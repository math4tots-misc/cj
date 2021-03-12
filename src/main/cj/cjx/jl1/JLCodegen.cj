package cjx.jl1

import cj.MapOf
import cjx.jl1.JLType
import cjx.jl1.JLError
import cj.FS
import cjx.jvm.JVMConstValue
import cj.Error
import cjx.jl1.JLIRLocal
import cjx.jvm.JVMCodeBuilder
import cjx.jl1.JLIRExpr
import cjx.jl1.JLIRMethod
import cjx.jvm.JVMClass
import cjx.jl1.JLIRClass
import cjx.jl1.JLContext

## jl1 code generator
class JLCodegen {
    static val sep = "/"
    val ctx: JLContext
    val outdir: String

    class FinallyJumpRegistry {
        val returnJumps: List[Int] = []
    }

    def emit(self) {
        for className in ctx.classMap.keys() {
            val cls = ctx.classMap[className]
            if not cls.isNative() {
                emitClass(cls)
            }
        }
    }

    def emitClass(self, cls: JLIRClass) {
        val lambdaNameFactory = LambdaNameFactory(cls.toJVMName() + "$l$")
        val jvmcls = JVMClass()
        jvmcls.thisClass = jvmcls.cp.classref(cls.toJVMName())
        jvmcls.superClass = jvmcls.cp.classref(cls.superClass.toJVMName())
        jvmcls.attributes.add(JVMClass.AttributeInfo(
            jvmcls.cp.utf8("SourceFile"),
            JVMClass.AttributeInfoData.sourceFile(
                JVMClass.SourceFileAttribute(
                    jvmcls.cp.utf8(cls.mark.filename)))))

        for jlfield in cls.fields {
            jvmcls.addField(jvmfield -> {
                jvmfield.accessFlags = JVMClass.cACC_PUBLIC
                if jlfield.isStatic() {
                    jvmfield.accessFlags = jvmfield.accessFlags | JVMClass.cACC_STATIC
                }
                if not jlfield.isMutable() {
                    jvmfield.accessFlags = jvmfield.accessFlags | JVMClass.cACC_FINAL
                }
                jvmfield.name = jlfield.name
                jvmfield.descriptor = jlfield.type.toJVMString()
            })
        }

        for jlmethod in cls.methods {
            jvmcls.addMethod(jvmmethod -> {
                jvmmethod.accessFlags = JVMClass.cACC_PUBLIC
                if jlmethod.isStatic() {
                    jvmmethod.accessFlags = jvmmethod.accessFlags | JVMClass.cACC_STATIC
                }
                if jlmethod.body.isEmpty() {
                    jvmmethod.accessFlags = jvmmethod.accessFlags | JVMClass.cACC_ABSTRACT
                }
                jvmmethod.name = jlmethod.name
                jvmmethod.descriptor = jlmethod.getJVMDescriptor()

                if val body = jlmethod.body {
                    jvmmethod.addCode(jvmcode -> {
                        val exprgen = ExprGen(
                            ctx,
                            outdir,
                            jvmcls.cp,
                            jvmcode,
                            lambdaNameFactory,
                            cls.toJVMName())
                        for parameter in jlmethod.parameters {
                            exprgen.addLocal(parameter)
                        }
                        exprgen.top(body)
                        jvmcode.maxLocals = exprgen.maxLocals
                    })
                }
            })
        }

        val relpath = cls.name.replace(".", sep) + ".class"
        val outpath = outdir + sep + relpath
        val jvmbuffer = jvmcls.toBuffer()
        FS.writeFileBytes(outpath, jvmbuffer)
    }

    class LambdaNameFactory {
        val prefix: String
        var nextId = 0

        def newName(self): String {
            val name = prefix + nextId
            nextId = nextId + 1
            name
        }
    }

    ## Expression code generator
    class ExprGen {
        val ctx: JLContext
        val outdir: String
        val cp: JVMClass.ConstantPool
        val jvmcode: JVMCodeBuilder
        val lambdaNameFactory: LambdaNameFactory
        val thisJVMClassName: String
        var finallyJumpRegistry: Nullable[FinallyJumpRegistry] = null

        ## Maps local variable ids to their JVM local variable slot
        val localMap: Map[Int, Int] = MapOf()
        var localSize: Int = 0
        val localSizeStack: List[Int] = []
        val localStack: List[List[JLIRLocal]] = [[]]
        var maxLocals: Int = 0 # TODO: compare with JVMCodeBuilder's inferred maxLocals

        def addLocal(self, localvar: JLIRLocal) {
            Assert.that(localvar.id not in localMap)
            val slot = localSize
            localSize = localSize + localvar.type.getJVMSlotSize()
            if localSize > maxLocals {
                maxLocals = localSize
            }
            localStack.last().add(localvar)
            localMap[localvar.id] = slot
        }

        def addLocalThisForLambda(self) {
            addLocal(JLIRLocal(
                Default(),
                -1,
                [],
                "this$lambda",
                JLType.int(),
            ))
        }

        def pushScope(self) {
            localSizeStack.add(localSize)
            localStack.add([])
        }

        def popScope(self) {
            localSize = localSizeStack.pop()
            for local in localStack.pop() {
                localMap.removeOrThrow(local.id)
            }
        }

        ## Emit an expression from the top of the method
        def top(self, expr: JLIRExpr) {
            emit(expr)
            if not expr.terminatesFlow {
                when expr.type {
                    case noreturn = ()
                    case void = jvmcode.return_()
                    case bool = jvmcode.ireturn()
                    case byte = jvmcode.ireturn()
                    case char = jvmcode.ireturn()
                    case short = jvmcode.ireturn()
                    case int = jvmcode.ireturn()
                    case long = jvmcode.lreturn()
                    case float = jvmcode.freturn()
                    case double = jvmcode.dreturn()
                    case array(inner) = jvmcode.areturn()
                    case klass(cls) = jvmcode.areturn()
                }
            }
        }

        def emit(self, expr: JLIRExpr) {
            when expr.data {
                case void() = ()
                case bool(b) = jvmcode.bipush(if b { 1 } else { 0 })
                case char(i) = jvmcode.ldc(JVMConstValue.int(i))
                case int(i) = jvmcode.ldc(JVMConstValue.int(i))
                case long(i) = jvmcode.ldc(JVMConstValue.long(i))
                case float(f) = jvmcode.ldc(JVMConstValue.float(f))
                case double(f) = jvmcode.ldc(JVMConstValue.double(f))
                case string(s) = jvmcode.ldc(JVMConstValue.string(s))
                case block(subexprs) = {
                    pushScope()
                    for subexpr in subexprs {
                        emit(subexpr)
                    }
                    popScope()
                }
                case call(methodref, args) = {
                    for arg in args {
                        emit(arg)
                    }
                    jvmcode.markLine(expr.mark.line)
                    if methodref.method.isStatic() {
                        jvmcode.invokestatic(
                            methodref.owner.toJVMName(),
                            methodref.method.name,
                            methodref.method.getJVMDescriptor())
                    } else if methodref.owner.isInterface() {
                        jvmcode.invokeinterface(
                            methodref.owner.toJVMName(),
                            methodref.method.name,
                            methodref.method.getJVMDescriptor())
                    } else {
                        jvmcode.invokevirtual(
                            methodref.owner.toJVMName(),
                            methodref.method.name,
                            methodref.method.getJVMDescriptor())
                    }
                    if expr.type.isNoReturn() {
                        emitThrowNoReturnError()
                    }
                }
                case callnew(methodref, args) = {
                    jvmcode.new_(methodref.owner.toJVMName())
                    jvmcode.dup()
                    for arg in args {
                        emit(arg)
                    }
                    jvmcode.markLine(expr.mark.line)
                    jvmcode.invokespecial(
                        methodref.owner.toJVMName(),
                        methodref.method.name,
                        methodref.method.getJVMDescriptor())
                }
                case declarelocal(local, init) = {
                    emit(init)
                    addLocal(local)
                    store(local)
                }
                case getlocal(local) = {
                    load(local)
                }
                case setlocal(local, valexpr) = {
                    # Try optimizing wth iinc for the really common case
                    val opt = if val incr = getIntAddAssignIncr(local, valexpr) {
                        val index = localMap[local.id]
                        if index < 128 and incr >= -128 and incr < 128 {
                            jvmcode.iinc(index, incr)
                            true
                        } else { false }
                    } else {
                        false
                    }
                    # If the optimization wasn't applicable, just set
                    # the local variable the simple way
                    if not opt {
                        emit(valexpr)
                        store(local)
                    }
                }
                case getstatic(fieldref) = {
                    jvmcode.getstatic(
                        fieldref.owner.toJVMName(),
                        fieldref.field.name,
                        fieldref.field.type.toJVMString())
                }
                case setstatic(fieldref, valexpr) = {
                    emit(valexpr)
                    jvmcode.putstatic(
                        fieldref.owner.toJVMName(),
                        fieldref.field.name,
                        fieldref.field.type.toJVMString())
                }
                case getfield(fieldref, owner) = {
                    emit(owner)
                    jvmcode.getfield(
                        fieldref.owner.toJVMName(),
                        fieldref.field.name,
                        fieldref.field.type.toJVMString())
                }
                case setfield(fieldref, owner, valexpr) = {
                    emit(owner)
                    emit(valexpr)
                    jvmcode.putfield(
                        fieldref.owner.toJVMName(),
                        fieldref.field.name,
                        fieldref.field.type.toJVMString())
                }
                case getcapture(capture) = {
                    jvmcode.aload(0)
                    jvmcode.getfield(
                        thisJVMClassName,
                        capture.name,
                        capture.type.toJVMString())
                }
                case not_(boolexpr) = {
                    emit(boolexpr)
                    jvmcode.ifeq(3 + 1 + 3)
                    jvmcode.iconst_0()
                    jvmcode.goto(3 + 1)
                    jvmcode.iconst_1()
                }
                case and_(args) = {
                    if args {
                        val jumpPosList: List[Int] = []
                        for arg in args {
                            emit(arg)
                            jumpPosList.add(jvmcode.code.size()); jvmcode.ifeq(0)
                        }
                        jvmcode.iconst_1()
                        jvmcode.goto(3 + 1)
                        val landPos = jvmcode.code.size(); jvmcode.iconst_0()
                        for jumpPos in jumpPosList {
                            Assert.that(landPos - jumpPos <= 32767)
                            val jumpPatchPos = jumpPos + 1
                            jvmcode.code.setInt16(jumpPatchPos, landPos - jumpPos)
                        }
                    } else {
                        jvmcode.iconst_1()
                    }
                }
                case or_(args) = {
                    if args {
                        val jumpPosList: List[Int] = []
                        for arg in args {
                            emit(arg)
                            jumpPosList.add(jvmcode.code.size()); jvmcode.ifne(0)
                        }
                        jvmcode.iconst_0()
                        jvmcode.goto(3 + 1)
                        val landPos = jvmcode.code.size(); jvmcode.iconst_1()
                        for jumpPos in jumpPosList {
                            Assert.that(landPos - jumpPos <= 32767)
                            val jumpPatchPos = jumpPos + 1
                            jvmcode.code.setInt16(jumpPatchPos, landPos - jumpPos)
                        }
                    } else {
                        jvmcode.iconst_0()
                    }
                }
                case if_(cond, body, other) = {
                    emit(cond)
                    val jumpPos1 = jvmcode.code.size(); jvmcode.ifeq(0)
                    emit(body)
                    val jumpPos2 = jvmcode.code.size(); jvmcode.goto(0)
                    val landPos1 = jvmcode.code.size(); emit(other)
                    val landPos2 = jvmcode.code.size()

                    Assert.that(landPos1 - jumpPos1 <= 32767)
                    Assert.that(landPos2 - jumpPos2 <= 32767)
                    val jumpPatchPos1 = jumpPos1 + 1
                    val jumpPatchPos2 = jumpPos2 + 1
                    jvmcode.code.setInt16(jumpPatchPos1, landPos1 - jumpPos1)
                    jvmcode.code.setInt16(jumpPatchPos2, landPos2 - jumpPos2)
                }
                case while_(cond, body) = {
                    val landPos1 = jvmcode.code.size(); emit(cond)
                    val jumpPos2 = jvmcode.code.size(); jvmcode.ifeq(0)
                    emit(body)
                    val jumpPos1 = jvmcode.code.size(); jvmcode.goto(0)
                    val landPos2 = jvmcode.code.size()

                    Assert.that(landPos1 - jumpPos1 <= 32767)
                    Assert.that(landPos2 - jumpPos2 <= 32767)
                    val jumpPatchPos1 = jumpPos1 + 1
                    val jumpPatchPos2 = jumpPos2 + 1
                    jvmcode.code.setInt16(jumpPatchPos1, landPos1 - jumpPos1)
                    jvmcode.code.setInt16(jumpPatchPos2, landPos2 - jumpPos2)
                }
                case throw_(inner) = {
                    emit(inner)
                    jvmcode.athrow()
                }
                case trycatch(body, entries) = {
                    val bodyStartPc = jvmcode.code.size()
                    val jumpPosList: List[Int] = []
                    emit(body)
                    jumpPosList.add(jvmcode.code.size()); jvmcode.goto(0)
                    val bodyEndPc = jvmcode.code.size()
                    for (local, ecls, handler) in entries {
                        val handlerStartPc = jvmcode.code.size()
                        addLocal(local)
                        store(local)
                        emit(handler)
                        jumpPosList.add(jvmcode.code.size()); jvmcode.goto(0)
                        jvmcode.exceptionTable.add(JVMClass.ExceptionTableEntry(
                            bodyStartPc,
                            bodyEndPc,
                            handlerStartPc,
                            cp.classref(ecls.toJVMName())))
                    }
                    val okLandPos = jvmcode.code.size()

                    for jumpPos in jumpPosList {
                        Assert.that(okLandPos - jumpPos <= 32767)
                        val jumpPatchPos = jumpPos + 1
                        jvmcode.code.setInt16(jumpPatchPos, okLandPos - jumpPos)
                    }
                }
                case tryfinally(body, fin) = {
                    if finallyJumpRegistry.isPresent() {
                        # TODO: put this check in ExpressionSolver or remove this limitation
                        throw JLError("finally blocks may not be nested", [expr.mark])
                    }
                    finallyJumpRegistry = null(FinallyJumpRegistry())
                    val bodyStartPc = jvmcode.code.size()
                    emit(body)
                    val okJumpPos = jvmcode.code.size(); jvmcode.goto(0)
                    val bodyEndPc = jvmcode.code.size()
                    val finallyThrowLandPos = jvmcode.code.size(); emit(fin)
                    jvmcode.athrow()
                    val okLandPos = jvmcode.code.size(); emit(fin)

                    if finallyJumpRegistry.get().returnJumps {
                        throw JLError(
                            "Early returns from within finally are not yet supported",
                            [expr.mark])
                    }

                    # register the location to jump to when no exceptions are thrown
                    Assert.that(okLandPos - okJumpPos <= 32767)
                    val okJumpPatchPos = okJumpPos + 1
                    jvmcode.code.setInt16(okJumpPatchPos, okLandPos - okJumpPos)

                    # Add entry in exception table for which finally to trigger
                    # when an exception is thrown
                    jvmcode.exceptionTable.add(JVMClass.ExceptionTableEntry(
                        bodyStartPc,
                        bodyEndPc,
                        finallyThrowLandPos,
                        0, # catch any
                    ))
                    finallyJumpRegistry = null
                }
                case upcast(arg) = {
                    emit(arg)
                }
                case downcast(arg) = {
                    emit(arg)
                    jvmcode.checkcast(when expr.type {
                        case klass(cls) = cls.toJVMName()
                        else = throw JLError("FUBAR downcast", [expr.mark])
                    })
                }
                case lambda(captures, params, body) = {
                    val lambdaClassName = lambdaNameFactory.newName()
                    val ljvmcls = JVMClass()
                    val fncls = when expr.type {
                        case klass(fncls) = fncls
                        else = throw JLError("FUBAR lambda type must be a class", [expr.mark])
                    }
                    val initDescriptor = (
                        "(" + "".join(captures.map(c -> c.type.toJVMString())) + ")V")

                    # emit an anonymous class for the lambda expression
                    ljvmcls.thisClass = ljvmcls.cp.classref(lambdaClassName)
                    ljvmcls.superClass = ljvmcls.cp.classref(fncls.toJVMName())
                    for capture in captures {
                        ljvmcls.addField(ljvmfield -> {
                            ljvmfield.accessFlags = JVMClass.cACC_FINAL
                            ljvmfield.name = capture.name
                            ljvmfield.descriptor = capture.type.toJVMString()
                        })
                    }
                    ljvmcls.addMethod(ljvmmethod -> {
                        ljvmmethod.accessFlags = JVMClass.cACC_PUBLIC
                        ljvmmethod.name = "<init>"
                        ljvmmethod.descriptor = initDescriptor
                        ljvmmethod.addCode(ljvmcode -> {
                            # invoke super
                            ljvmcode.aload(0)
                            ljvmcode.invokespecial(fncls.toJVMName(), "<init>", "()V")

                            # set all field values
                            for i = 0; i < captures.size(); i++ {
                                ljvmcode.aload(0)
                                ljvmcode.aload(i + 1)
                                ljvmcode.putfield(
                                    lambdaClassName,
                                    captures[i].name,
                                    captures[i].type.toJVMString())
                            }
                            ljvmcode.return_()

                            val maxLocals = 1 + captures.map(
                                c -> c.type.getJVMSlotSize()).fold(0, (a, b) -> a + b)
                            ljvmcode.maxLocals = maxLocals
                        })
                    })
                    ljvmcls.addMethod(ljvmmethod -> {
                        ljvmmethod.accessFlags = JVMClass.cACC_PUBLIC
                        ljvmmethod.name = "call"
                        ljvmmethod.descriptor = (
                            fncls.getMethodRef(expr.mark, "call").method.getJVMDescriptor())
                        ljvmmethod.addCode(ljvmcode -> {
                            val exprgen = ExprGen(
                                ctx,
                                outdir,
                                ljvmcls.cp,
                                ljvmcode,
                                lambdaNameFactory,
                                lambdaClassName)
                            exprgen.addLocalThisForLambda()
                            for param in params {
                                exprgen.addLocal(param)
                            }
                            exprgen.top(body)
                            ljvmcode.maxLocals = exprgen.maxLocals
                        })
                    })
                    val relpath = lambdaClassName.replace("/", JLCodegen.sep) + ".class"
                    val outpath = outdir + "/" + relpath
                    val ljvmbuffer = ljvmcls.toBuffer()
                    FS.writeFileBytes(outpath, ljvmbuffer)

                    # use the lambda class we just generated
                    jvmcode.new_(lambdaClassName)
                    jvmcode.dup()
                    for capture in captures {
                        when capture.source {
                            case local(local) = load(local)
                            case capture(capture) = {
                                jvmcode.aload(0)
                                jvmcode.getfield(
                                    thisJVMClassName,
                                    capture.name,
                                    capture.type.toJVMString())
                            }
                        }
                    }
                    jvmcode.invokespecial(lambdaClassName, "<init>", initDescriptor)
                }
                case operation(operator, args) = {
                    when operator {

                        # int ops
                        case iadd = emitBinop(args, () -> jvmcode.iadd())
                        case isub = emitBinop(args, () -> jvmcode.isub())
                        case imul = emitBinop(args, () -> jvmcode.imul())
                        case idiv = emitBinop(args, () -> jvmcode.idiv())
                        case irem = emitBinop(args, () -> jvmcode.irem())
                        case iand = emitBinop(args, () -> jvmcode.iand())
                        case ior = emitBinop(args, () -> jvmcode.ior())
                        case ixor = emitBinop(args, () -> jvmcode.ixor())
                        case ishl = emitBinop(args, () -> jvmcode.ishl())
                        case ishr = emitBinop(args, () -> jvmcode.ishr())
                        case ishru = emitBinop(args, () -> jvmcode.iushr())
                        case ineg = emitUnop(args, () -> jvmcode.ineg())
                        case i2b = emitUnop(args, () -> jvmcode.i2b())
                        case i2c = emitUnop(args, () -> jvmcode.i2c())
                        case i2d = emitUnop(args, () -> jvmcode.i2d())
                        case i2f = emitUnop(args, () -> jvmcode.i2f())
                        case i2l = emitUnop(args, () -> jvmcode.i2l())
                        case i2s = emitUnop(args, () -> jvmcode.i2s())
                        case ieq = emitIntCmp(args, offset -> jvmcode.if_icmpeq(offset))
                        case ine = emitIntCmp(args, offset -> jvmcode.if_icmpne(offset))
                        case ilt = emitIntCmp(args, offset -> jvmcode.if_icmplt(offset))
                        case ile = emitIntCmp(args, offset -> jvmcode.if_icmple(offset))
                        case igt = emitIntCmp(args, offset -> jvmcode.if_icmpgt(offset))
                        case ige = emitIntCmp(args, offset -> jvmcode.if_icmpge(offset))

                        # double ops
                        case dadd = emitBinop(args, () -> jvmcode.dadd())

                        # long ops
                        case l2i = {
                            Assert.equal(args.size(), 1)
                            emit(args[0])
                            jvmcode.l2i()
                        }

                        # string ops
                        case strcat = {
                            jvmcode.new_("java/lang/StringBuilder")
                            jvmcode.dup()
                            emit(args[0])
                            jvmcode.invokespecial(
                                "java/lang/StringBuilder", "<init>", "(Ljava/lang/String;)V")
                            for i = 1; i < args.size(); i++ {
                                emit(args[i])
                                jvmcode.invokevirtual(
                                    "java/lang/StringBuilder",
                                    "append",
                                    "(Ljava/lang/String;)Ljava/lang/StringBuilder;")
                            }
                            jvmcode.invokevirtual(
                                "java/lang/StringBuilder",
                                "toString",
                                "()Ljava/lang/String;")
                        }

                        # array ops
                        case arrayget = {
                            Assert.equal(args.size(), 2)
                            emit(args[0])
                            emit(args[1])
                            when args[0].type.arrayInnerType {
                                case noreturn() = throw Error("FUBAR arrayget noreturn[]")
                                case void() = throw Error("FUBAR arrayget void[]")
                                case bool() = jvmcode.baload()
                                case byte() = jvmcode.baload()
                                case char() = jvmcode.caload()
                                case short() = jvmcode.saload()
                                case int() = jvmcode.iaload()
                                case long() = jvmcode.laload()
                                case float() = jvmcode.faload()
                                case double() = jvmcode.daload()
                                case array(inner) = jvmcode.aaload()
                                case klass(cls) = jvmcode.aaload()
                            }
                        }
                        case arrayset = {
                            Assert.equal(args.size(), 3)
                            emit(args[0])
                            emit(args[1])
                            emit(args[2])
                            emitArraySet(args[0].type.arrayInnerType)
                        }
                        case arrayclear = {
                            Assert.equal(args.size(), 2)
                            emit(args[0])
                            emit(args[1])
                            emitClearType(args[0].type.arrayInnerType)
                            emitArraySet(args[0].type.arrayInnerType)
                        }
                        case arraylen = {
                            Assert.equal(args.size(), 1)
                            emit(args[0])
                            jvmcode.arraylength()
                        }
                        case arrayrealloc = {
                            Assert.equal(args.size(), 2)
                            emit(args[0])
                            emit(args[1])
                            val itemDescriptor: String = when args[0].type.arrayInnerType {
                                case array(inner) = "Ljava/lang/Object;"
                                case klass(cls) = "Ljava/lang/Object;"
                                else = args[0].type.arrayInnerType.toJVMString()
                            }
                            jvmcode.invokestatic(
                                "java/util/Arrays",
                                "copyOf",
                                "([" + itemDescriptor + "I)[" + itemDescriptor)
                            if (itemDescriptor == "Ljava/lang/Object;" and
                                    expr.type.toJVMString() != itemDescriptor) {
                                jvmcode.checkcast(expr.type.toJVMString())
                            }
                        }
                    }
                }
                case iaugfield(fieldref, owner, valexpr) = {
                    emit(owner)
                    jvmcode.dup()
                    jvmcode.getfield(
                        fieldref.owner.toJVMName(),
                        fieldref.field.name,
                        fieldref.field.type.toJVMString())
                    emit(valexpr)
                    jvmcode.iadd()
                    jvmcode.putfield(
                        fieldref.owner.toJVMName(),
                        fieldref.field.name,
                        fieldref.field.type.toJVMString())
                }
                case array(args) = {
                    val itemtype = expr.type.arrayInnerType
                    jvmcode.ldc(args.size())
                    emitNewArray(itemtype)
                    for i = 0; i < args.size(); i++ {
                        jvmcode.dup()
                        jvmcode.ldc(i)
                        emit(args[i])
                        emitArraySet(itemtype)
                    }
                }
                case arraynew(arg) = {
                    val itemtype = expr.type.arrayInnerType
                    emit(arg)
                    emitNewArray(itemtype)
                }
                case voidify(expr) = {
                    emit(expr)
                    when expr.type {
                        case noreturn = ()
                        case void = ()
                        case long = jvmcode.pop2()
                        case double = jvmcode.pop2()
                        else = jvmcode.pop()
                    }
                }
                case javacall(kind, ownerName, methodName, descriptor, args) = {
                    for arg in args {
                        emit(arg)
                    }
                    jvmcode.markLine(expr.mark.line)
                    switch kind {
                        case "static" = {
                            jvmcode.invokestatic(ownerName, methodName, descriptor)
                        }
                        case "virtual" = {
                            jvmcode.invokevirtual(ownerName, methodName, descriptor)
                        }
                        case "interface" = {
                            jvmcode.invokeinterface(ownerName, methodName, descriptor)
                        }
                        case "special" = {
                            jvmcode.invokespecial(ownerName, methodName, descriptor)
                        }
                        else = throw JLError("Unrecognized call kind " + kind, [expr.mark])
                    }
                    if expr.type.isNoReturn() {
                        emitThrowNoReturnError()
                    }
                }
                case javanew(ownerName, descriptor, args) = {
                    jvmcode.new_(ownerName)
                    jvmcode.dup()
                    for arg in args {
                        emit(arg)
                    }
                    jvmcode.markLine(expr.mark.line)
                    jvmcode.invokespecial(ownerName, "<init>", descriptor)
                }
                case javagetstatic(className, fieldName, descriptor) = {
                    jvmcode.getstatic(className, fieldName, descriptor)
                }
                case javasetstatic(className, fieldName, descriptor, valexpr) = {
                    emit(valexpr)
                    jvmcode.putstatic(className, fieldName, descriptor)
                }
                case javagetfield(className, fieldName, descriptor, owner) = {
                    emit(owner)
                    jvmcode.getfield(className, fieldName, descriptor)
                }
                case javasetfield(className, fieldName, descriptor, owner, valexpr) = {
                    emit(owner)
                    emit(valexpr)
                    jvmcode.putfield(className, fieldName, descriptor)
                }
                case initfield(fieldref, valexpr) = {
                    if fieldref.field.isStatic() {
                        emit(valexpr)
                        jvmcode.putstatic(
                            fieldref.owner.toJVMName(),
                            fieldref.field.name,
                            fieldref.field.type.toJVMString())
                    } else {
                        jvmcode.aload(0)
                        emit(valexpr)
                        jvmcode.putfield(
                            fieldref.owner.toJVMName(),
                            fieldref.field.name,
                            fieldref.field.type.toJVMString())
                    }
                }
            }
        }

        private def emitThrowNoReturnError(self) {
            jvmcode.new_("java/lang/RuntimeException")
            jvmcode.dup()
            jvmcode.ldc("noreturn assertion error")
            jvmcode.invokespecial(
                "java/lang/RuntimeException", "<init>", "(Ljava/lang/String;)V")
            jvmcode.athrow()
        }

        private def emitNewArray(self, itemtype: JLType) {
            when itemtype {
                case noreturn() = throw Error("FUBAR")
                case void() = throw Error("FUBAR")
                case bool() = jvmcode.newarray("bool")
                case char() = jvmcode.newarray("char")
                case float() = jvmcode.newarray("float")
                case double() = jvmcode.newarray("double")
                case byte() = jvmcode.newarray("byte")
                case short() = jvmcode.newarray("short")
                case int() = jvmcode.newarray("int")
                case long() = jvmcode.newarray("long")
                case array(inner) = jvmcode.anewarray(inner.toJVMString())
                case klass(cls) = jvmcode.anewarray(cls.toJVMName())
            }
        }

        ## Emit the type that would "clear out" a value of the given type
        ## i.e. the zero values for most primitives, and null for reference types.
        private def emitClearType(self, type: JLType) {
            when type {
                case noreturn() = throw Error("FUBAR emitClearType noreturn")
                case void() = throw Error("FUBAR emitClearType void")
                case bool() = jvmcode.iconst_0()
                case byte() = jvmcode.iconst_0()
                case char() = jvmcode.iconst_0()
                case short() = jvmcode.iconst_0()
                case int() = jvmcode.iconst_0()
                case long() = jvmcode.lconst_0()
                case float() = jvmcode.fconst_0()
                case double() = jvmcode.dconst_0()
                case array(inner) = jvmcode.aconst_null()
                case klass(cls) = jvmcode.aconst_null()
            }
        }

        private def emitArraySet(self, type: JLType) {
            when type {
                case noreturn() = throw Error("FUBAR emitArraySet noreturn[]")
                case void() = throw Error("FUBAR emitArraySet void[]")
                case bool() = jvmcode.bastore()
                case byte() = jvmcode.bastore()
                case char() = jvmcode.castore()
                case short() = jvmcode.sastore()
                case int() = jvmcode.iastore()
                case long() = jvmcode.lastore()
                case float() = jvmcode.fastore()
                case double() = jvmcode.dastore()
                case array(inner) = jvmcode.aastore()
                case klass(cls) = jvmcode.aastore()
            }
        }

        private def emitBinop(self, args: List[JLIRExpr], f: Fn[Unit]) {
            emit(args[0])
            for i = 1; i < args.size(); i++ {
                emit(args[i])
                f.call()
            }
        }

        private def emitUnop(self, args: List[JLIRExpr], f: Fn[Unit]) {
            Assert.equal(args.size(), 1)
            emit(args[0])
            f.call()
        }

        private def emitIntCmp(self, args: List[JLIRExpr], f: Fn[Int, Unit]) {
            Assert.equal(args.size(), 2)
            emit(args[0])
            emit(args[1])

            # f MUST emit a 3-byte branching instruction
            f.call(3 + 1 + 3) # 3-bytes (op, u16-branch-loc)
            jvmcode.iconst_0() # 1-byte (op)
            jvmcode.goto(3 + 1) # 3-bytes (op, u16-branch-loc)
            jvmcode.iconst_1() # 1-byte
        }

        private def load(self, local: JLIRLocal) {
            val index = localMap[local.id]
            when local.type {
                case noreturn() = throw Error("getlocal noreturn variable")
                case void() = throw Error("getlocal void variable")
                case bool() = jvmcode.iload(index)
                case byte() = jvmcode.iload(index)
                case char() = jvmcode.iload(index)
                case short() = jvmcode.iload(index)
                case int() = jvmcode.iload(index)
                case long() = jvmcode.lload(index)
                case float() = jvmcode.fload(index)
                case double() = jvmcode.dload(index)
                case array(inner) = jvmcode.aload(index)
                case klass(cls) = jvmcode.aload(index)
            }
        }

        private def store(self, local: JLIRLocal) {
            val index = localMap[local.id]
            when local.type {
                case noreturn() = throw Error("getlocal noreturn variable")
                case void() = throw Error("getlocal void variable")
                case bool() = jvmcode.istore(index)
                case byte() = jvmcode.istore(index)
                case char() = jvmcode.istore(index)
                case short() = jvmcode.istore(index)
                case int() = jvmcode.istore(index)
                case long() = jvmcode.lstore(index)
                case float() = jvmcode.fstore(index)
                case double() = jvmcode.dstore(index)
                case array(inner) = jvmcode.astore(index)
                case klass(cls) = jvmcode.astore(index)
            }
        }

        private def getIntAddAssignIncr(local: JLIRLocal, setexpr: JLIRExpr): Nullable[Int] {
            when setexpr.data {
                case operation(operator, args) = when operator {
                    case iadd = when args[0].data {
                        case getlocal(srclocal) = {
                            if local.id == srclocal.id {
                                when args[1].data {
                                    case int(i) = null(i)
                                    else = null
                                }
                            } else { null }
                        }
                        else = null
                    }
                    else = null
                }
                else = null
            }
        }
    }
}
