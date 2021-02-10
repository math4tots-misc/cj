package cjx.jl1

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
@derive(new)
class JLCodegen {
    val ctx: JLContext
    val outdir: String

    def emit(self) {
        for className in ctx.classMap.keys() {
            val cls = ctx.classMap[className]
            if not cls.isNative() {
                val jvmcls = emitClass(cls)
                val relpath = cls.name.replace(".", "/") + ".class"
                val outpath = outdir + "/" + relpath
                val jvmbuffer = jvmcls.toBuffer()
                FS.writeFileBytes(outpath, jvmbuffer)
            }
        }
    }

    def emitClass(self, cls: JLIRClass): JVMClass {
        val jvmcls = JVMClass()
        jvmcls.thisClass = jvmcls.cp.classref(cls.toJVMName())
        jvmcls.superClass = jvmcls.cp.classref("java/lang/Object")
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
                jvmmethod.name = jlmethod.name
                jvmmethod.descriptor = jlmethod.getJVMDescriptor()

                if null(body) = jlmethod.body {
                    jvmmethod.addCode(jvmcode -> {
                        val exprgen = ExprGen(
                            ctx,
                            cls,
                            jvmcls,
                            jvmmethod,
                            jlmethod,
                            jvmcode)
                        exprgen.top(body)
                        jvmcode.maxLocals = exprgen.maxLocals
                    })
                }
            })
        }

        jvmcls
    }

    ## Expression code generator
    @derive(new)
    class ExprGen {
        val ctx: JLContext
        val cls: JLIRClass
        val jvmcls: JVMClass
        val jvmmethod: JVMClass.MethodBuilder
        val jlmethod: JLIRMethod
        val jvmcode: JVMCodeBuilder

        ## Maps local variable ids to their JVM local variable slot
        val localMap: Map[Int, Int] = Map()
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
            for parameter in jlmethod.parameters {
                addLocal(parameter)
            }
            emit(expr)
            when jlmethod.returnType {
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
                }
                case callnew(methodref, args) = {
                    jvmcode.new_(methodref.owner.toJVMName())
                    jvmcode.dup()
                    for arg in args {
                        emit(arg)
                    }
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
                    val index = localMap[local.id]
                    when local.type {
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
                case setlocal(local, valexpr) = {
                    emit(valexpr)
                    store(local)
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
                    jvmcode.code.setI16(jumpPatchPos1, landPos1 - jumpPos1)
                    jvmcode.code.setI16(jumpPatchPos2, landPos2 - jumpPos2)
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
                    jvmcode.code.setI16(jumpPatchPos1, landPos1 - jumpPos1)
                    jvmcode.code.setI16(jumpPatchPos2, landPos2 - jumpPos2)
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
                        case l2i = {
                            Assert.equal(args.size(), 1)
                            emit(args[0])
                            jvmcode.l2i()
                        }
                    }
                }
                case voidify(expr) = {
                    when expr.type {
                        case void = ()
                        case long = jvmcode.pop2()
                        case double = jvmcode.pop2()
                        else = jvmcode.pop()
                    }
                }
                case calljava(kind, ownerName, methodName, descriptor, args) = {
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

        private def store(self, local: JLIRLocal) {
            val index = localMap[local.id]
            when local.type {
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
    }
}
