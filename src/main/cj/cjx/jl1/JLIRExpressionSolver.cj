package cjx.jl1

import cjx.jl1.JLIRFieldRef
import cjx.jl1.JLParser
import cjx.jl1.JLIRMetaSolver
import cjx.jl1.JLIRMethodRef
import cjx.jl1.JLMark
import cjx.jl1.JLIRExpr
import cjx.jl1.JLAstExpr
import cjx.jl1.JLIRLocal
import cjx.jl1.JLIRMethod
import cjx.jl1.JLIRField
import cjx.jl1.JLError
import cjx.jl1.JLIRLocalContext
import cj.Error
import cjx.jl1.JLType
import cjx.jl1.JLAstType
import cjx.jl1.JLAstClass
import cjx.jl1.JLContext
import cjx.jl1.JLIRClass
import cjx.jl1.JLAstFile

@derive(new)
class JLIRExpressionSolver {
    static val homogeneousIntOps: Map[JLAstExpr.Operator, JLIRExpr.Operator] = Map(
        JLAstExpr.Operator.add(): JLIRExpr.Operator.iadd(),
        JLAstExpr.Operator.sub(): JLIRExpr.Operator.isub(),
        JLAstExpr.Operator.mul(): JLIRExpr.Operator.imul(),
        JLAstExpr.Operator.div(): JLIRExpr.Operator.idiv(),
        JLAstExpr.Operator.rem(): JLIRExpr.Operator.irem(),
        JLAstExpr.Operator.and_(): JLIRExpr.Operator.iand(),
        JLAstExpr.Operator.or_(): JLIRExpr.Operator.ior(),
        JLAstExpr.Operator.xor(): JLIRExpr.Operator.ixor(),
        JLAstExpr.Operator.shl(): JLIRExpr.Operator.ishl(),
        JLAstExpr.Operator.shr(): JLIRExpr.Operator.ishr(),
        JLAstExpr.Operator.shru(): JLIRExpr.Operator.ishru(),
    )

    static val comparisonIntOps: Map[JLAstExpr.Operator, JLIRExpr.Operator] = Map(
        JLAstExpr.Operator.eq(): JLIRExpr.Operator.ieq(),
        JLAstExpr.Operator.ne(): JLIRExpr.Operator.ine(),
        JLAstExpr.Operator.le(): JLIRExpr.Operator.ile(),
        JLAstExpr.Operator.lt(): JLIRExpr.Operator.ilt(),
        JLAstExpr.Operator.ge(): JLIRExpr.Operator.ige(),
        JLAstExpr.Operator.gt(): JLIRExpr.Operator.igt(),
    )

    static val homogeneousUnaryIntOps: Map[JLAstExpr.Operator, JLIRExpr.Operator] = Map(
        JLAstExpr.Operator.neg(): JLIRExpr.Operator.ineg(),
    )

    static val homogeneousDoubleOps: Map[JLAstExpr.Operator, JLIRExpr.Operator] = Map(
        JLAstExpr.Operator.add(): JLIRExpr.Operator.dadd(),
    )

    val lctx: JLIRLocalContext

    def __get_ctx(self): JLContext = lctx.ctx

    def solveExpression(
            self,
            astExpr: JLAstExpr,
            expectedType: Nullable[JLType]): JLIRExpr {
        val irExpr = solveExpressionUnchecked(astExpr, expectedType)

        if null(etype) = expectedType {
            checkTypeAndCast(etype, irExpr)
        } else {
            # If a void type was not specifically requested, it's not allowed
            if irExpr.type.isVoid() {
                throw JLError("a void expression is not allowed here", [astExpr.mark])
            }
            irExpr
        }
    }

    def voidify(expr: JLIRExpr): JLIRExpr {
        when expr.type {
            case void() = expr
            else = JLIRExpr(expr.mark, JLType.void(), JLIRExpr.Data.voidify(expr))
        }
    }

    def solveVoidExpression(self, astExpr: JLAstExpr): JLIRExpr = (
        solveExpression(astExpr, null(JLType.void())))

    def solveTruthyCoercedExpression(
            self,
            astExpr: JLAstExpr): JLIRExpr {
        val mark = astExpr.mark
        val irExpr = solveExpressionUnchecked(astExpr, null)
        val inttype = JLType.int()
        val nullableIrExpr: Nullable[JLIRExpr] = when irExpr.type {
            case void() = null
            case bool() = null(irExpr)
            case int() = null(irExpr)
            case klass(cls) = {
                if cls.name == "java.lang.String" {
                    null(callVirtualJavaMethod(
                        mark, "java/lang/String", "length", "()I", inttype, [irExpr]))
                } else {
                    null
                }
            }
            else = null
        }

        if null(ie) = nullableIrExpr {
            ie
        } else {
            throw JLError("Expected bool expression", [astExpr.mark])
        }
    }

    def solveStringCoercedExpression(
            self,
            astExpr: JLAstExpr): JLIRExpr {
        val mark = astExpr.mark
        val irExpr = solveExpressionUnchecked(astExpr, null)
        val strtype = getStringType()

        val nullableIrExpr: Nullable[JLIRExpr] = when irExpr.type {
            case void() = null
            case bool() = null(callStaticJavaMethod(
                mark, "java/lang/Boolean", "toString", "(Z)Ljava/lang/String;", strtype, [irExpr]))
            case char() = null
            case int() = null(callStaticJavaMethod(
                mark, "java/lang/Integer", "toString", "(I)Ljava/lang/String;", strtype, [irExpr]))
            case float() = null(callStaticJavaMethod(
                mark, "java/lang/Float", "toString", "(F)Ljava/lang/String;", strtype, [irExpr]))
            case double() = null(callStaticJavaMethod(
                mark, "java/lang/Double", "toString", "(D)Ljava/lang/String;", strtype, [irExpr]))
            case long() = null(callStaticJavaMethod(
                mark, "java/lang/Long", "toString", "(J)Ljava/lang/String;", strtype, [irExpr]))
            case klass(cls) = if cls.name == "java.lang.String" { null(irExpr) } else {
                    null(callVirtualJavaMethod(
                        mark,
                        "java/lang/Object",
                        "toString",
                        "()Ljava/lang/String;",
                        strtype,
                        [irExpr]))
                }
            else = null
        }

        if null(ie) = nullableIrExpr {
            ie
        } else {
            throw JLError("Expected String expression", [astExpr.mark])
        }
    }

    def callStaticJavaMethod(
            self,
            mark: JLMark,
            className: String,
            methodName: String,
            descriptor: String,
            returnType: JLType,
            args: List[JLIRExpr]): JLIRExpr {
        JLIRExpr(mark, returnType, JLIRExpr.Data.javacall(
            "static", className, methodName, descriptor, args))
    }

    def callVirtualJavaMethod(
            self,
            mark: JLMark,
            className: String,
            methodName: String,
            descriptor: String,
            returnType: JLType,
            args: List[JLIRExpr]): JLIRExpr {
        JLIRExpr(mark, returnType, JLIRExpr.Data.javacall(
            "virtual", className, methodName, descriptor, args))
    }

    def callInterfaceJavaMethod(
            self,
            mark: JLMark,
            className: String,
            methodName: String,
            descriptor: String,
            returnType: JLType,
            args: List[JLIRExpr]): JLIRExpr {
        JLIRExpr(mark, returnType, JLIRExpr.Data.javacall(
            "interface", className, methodName, descriptor, args))
    }

    def getBuiltinClass(self, qualifiedName: String): JLIRClass = (
        ctx.getClass(Default(), qualifiedName, true))
    def getObjectClass(self): JLIRClass = getBuiltinClass("java.lang.Object")
    def getObjectType(self): JLType = JLType.klass(getObjectClass())
    def getStringClass(self): JLIRClass = getBuiltinClass("java.lang.String")
    def getStringType(self): JLType = JLType.klass(getStringClass())

    def solveExpressionUnchecked(
            self,
            astExpr: JLAstExpr,
            expectedType: Nullable[JLType]): JLIRExpr {

        val mark = astExpr.mark

        val irExpr: JLIRExpr = when astExpr.data {
            case bool(x) = JLIRExpr(mark, JLType.bool(), JLIRExpr.Data.bool(x))
            case char(x) = JLIRExpr(mark, JLType.char(), JLIRExpr.Data.char(x))
            case int(x) = JLIRExpr(mark, JLType.int(), JLIRExpr.Data.int(x))
            case double(x) = JLIRExpr(mark, JLType.double(), JLIRExpr.Data.double(x))
            case string(x) = JLIRExpr(mark, getStringType(), JLIRExpr.Data.string(x))
            case block(astExprs) = {
                if astExprs {
                    val irExprs: List[JLIRExpr] = []
                    lctx.pushScope()
                    for i = 0; i + 1 < astExprs.size(); i++ {
                        irExprs.add(solveVoidExpression(astExprs[i]))
                    }
                    irExprs.add(solveExpression(astExprs.last(), expectedType))
                    lctx.popScope()
                    JLIRExpr(mark, irExprs.last().type, JLIRExpr.Data.block(irExprs))
                } else {
                    JLIRExpr(mark, JLType.void(), JLIRExpr.Data.void())
                }
            }
            case callnew(astOwnerType, astArgs) = {
                val ownertype = lctx.solveFieldType(astOwnerType)
                when ownertype {
                    case void() = throw JLError("FUBAR callnew void", [mark])
                    case array(inner) = {
                        Assert.equal(astArgs.size(), 1)
                        val arg = solveExpression(astArgs[0], null(JLType.int()))
                        JLIRExpr(
                            mark,
                            ownertype,
                            JLIRExpr.Data.arraynew(arg))
                    }
                    case klass(ownercls) = {
                        if ownercls.isInterface() or ownercls.isAbstract() {
                            throw JLError(
                                "new cannot be used with interface or abstract classes", [mark])
                        }
                        val methodref = ownercls.getMethodRef(mark, "<init>")
                        # TODO: remove this 'dummyThis' arg hack
                        val astArgsWithDummyThis = [JLAstExpr(mark, JLAstExpr.Data.int(0))]
                        astArgsWithDummyThis.addAll(astArgs)
                        val irArgsWithDummyThis = checkMethodArgs(
                            false,
                            mark,
                            methodref,
                            astArgsWithDummyThis,
                            [JLIRExpr(mark, JLType.klass(ownercls), JLIRExpr.Data.int(0))])
                        JLIRExpr(
                            mark,
                            JLType.klass(ownercls),
                            JLIRExpr.Data.callnew(methodref, irArgsWithDummyThis[1:]))
                    }
                    else = throw JLError(
                        "" + ownertype + " does not support the 'new' operator", [mark])
                }
            }
            case calltype(astOwnerType, astArgs) = {
                val ownercls = lctx.solveClass(astOwnerType)
                solveExpressionUnchecked(
                    JLAstExpr(
                        mark,
                        if ownercls.getMethodRefOrNull("jl$new").isPresent() {
                            # Call ".jl$new" if present
                            JLAstExpr.Data.callstatic(astOwnerType, "jl$new", astArgs)
                        } else {
                            # Otherwise, fallback to calling ".new"
                            JLAstExpr.Data.callnew(astOwnerType, astArgs)
                        }),
                    expectedType)
            }
            case callstatic(astOwnerType, methodName, astArgs) = {
                val ownercls = lctx.solveClass(astOwnerType)
                if null(methodref) = ownercls.getMethodRefOrNull(methodName) {
                    val methodref = ownercls.getMethodRef(mark, methodName)
                    val irArgs = checkMethodArgs(true, mark, methodref, astArgs, [])
                    JLIRExpr(mark, methodref.method.returnType, JLIRExpr.Data.call(
                        methodref, irArgs))
                } else if null(methodTemplate) = ownercls.getMethodTemplateOrNull(methodName) {
                    val irArgs: List[JLIRExpr] = []
                    val templateArgs = lctx.inferTemplateArgs(
                        self, mark, methodTemplate, expectedType, astArgs, irArgs)
                    val methodref = ctx.getReifiedMethod(mark, ownercls, methodTemplate, templateArgs)
                    checkMethodArgs(true, mark, methodref, astArgs, irArgs)
                    JLIRExpr(mark, methodref.method.returnType, JLIRExpr.Data.call(
                        methodref, irArgs))
                } else {
                    throw JLError("Method " + methodName + " not found", [mark])
                }
            }
            case callinstance(methodName, astArgs) = {
                val irOwner = solveExpression(astArgs[0], null)
                handleInstanceMethod(mark, expectedType, methodName, astArgs, irOwner)
            }
            case callname(methodName, astArgs) = {
                # syntactic sugar for callstatic or callinstance
                val ownercls = lctx.thisClass
                val methodref = ownercls.getMethodRef(mark, methodName)
                if methodref.method.isStatic() {
                    solveExpression(JLAstExpr(mark, JLAstExpr.Data.callstatic(
                        ownercls.toAstType(mark),
                        methodName,
                        astArgs)), expectedType)
                } else {
                    val newAstArgs = [JLAstExpr(mark, JLAstExpr.Data.this())]
                    newAstArgs.addAll(astArgs)
                    solveExpression(JLAstExpr(mark, JLAstExpr.Data.callinstance(
                        methodName,
                        newAstArgs)), expectedType)
                }
            }
            case getstatic(astClassType, fieldName) = {
                val ownercls = lctx.solveClass(astClassType)
                val fieldref = ownercls.getFieldRef(mark, fieldName)
                if not fieldref.field.isStatic() {
                    throw JLError("" + fieldref + " is non-static", [mark])
                }
                JLIRExpr(mark, fieldref.field.type, JLIRExpr.Data.getstatic(fieldref))
            }
            case setstatic(astClassType, fieldName, astValexpr) = {
                val ownercls = lctx.solveClass(astClassType)
                val fieldref = ownercls.getFieldRef(mark, fieldName)
                if not fieldref.field.isStatic() {
                    throw JLError("" + fieldref + " is non-static", [mark])
                }
                if not fieldref.field.isMutable() {
                    throw JLError("" + fieldref + " is not mutable", [mark])
                }
                val valexpr = solveExpression(astValexpr, null(fieldref.field.type))
                JLIRExpr(mark, JLType.void(), JLIRExpr.Data.setstatic(fieldref, valexpr))
            }
            case getfield(astOwner, fieldName) = {
                val irOwner = solveExpression(astOwner, null)
                val ownercls = when irOwner.type {
                    case klass(ownercls) = ownercls
                    else = {
                        throw JLError("" + irOwner.type + " values do not have fields", [mark])
                    }
                }
                val fieldref = ownercls.getFieldRef(mark, fieldName)
                if fieldref.field.isStatic() {
                    throw JLError("" + fieldref + " is static", [mark])
                }
                JLIRExpr(mark, fieldref.field.type, JLIRExpr.Data.getfield(fieldref, irOwner))
            }
            case setfield(astOwner, fieldName, astValexpr) = {
                val irOwner = solveExpression(astOwner, null)
                val ownercls = when irOwner.type {
                    case klass(ownercls) = ownercls
                    else = {
                        throw JLError("" + irOwner.type + " values do not have fields", [mark])
                    }
                }
                val fieldref = ownercls.getFieldRef(mark, fieldName)
                if fieldref.field.isStatic() {
                    throw JLError("" + fieldref + " is static", [mark])
                }
                if not fieldref.field.isMutable() {
                    throw JLError("" + fieldref + " is not mutable", [mark])
                }
                val valexpr = solveExpression(astValexpr, null(fieldref.field.type))
                JLIRExpr(mark, JLType.void(), JLIRExpr.Data.setfield(
                    fieldref, irOwner, valexpr))
            }
            case getvar(name) = {
                if null(local) = lctx.getLocalOrNull(name) {
                    JLIRExpr(mark, local.type, JLIRExpr.Data.getlocal(local))
                } else {
                    val ownercls = lctx.thisClass
                    if null(fieldref) = ownercls.getFieldRefOrNull(name) {
                        if fieldref.field.isStatic() {
                            solveExpression(
                                JLAstExpr(mark, JLAstExpr.Data.getstatic(
                                    ownercls.toAstType(mark), name)),
                                expectedType)
                        } else {
                            solveExpression(
                                JLAstExpr(mark, JLAstExpr.Data.getfield(
                                    JLAstExpr(mark, JLAstExpr.Data.this()), name)),
                                expectedType)
                        }
                    } else {
                        throw JLError("Variable " + name + " not found", [mark])
                    }
                }
            }
            case setvar(name, astValexpr) = {
                if null(local) = lctx.getLocalOrNull(name) {
                    if not local.isMutable() {
                        throw JLError("Variable " + name + " is not mutable", [mark])
                    }
                    val valexpr = solveExpression(astValexpr, null(local.type))
                    JLIRExpr(mark, JLType.void(), JLIRExpr.Data.setlocal(local, valexpr))
                } else {
                    val ownercls = lctx.thisClass
                    if null(fieldref) = ownercls.getFieldRefOrNull(name) {
                        if fieldref.field.isStatic() {
                            solveExpression(
                                JLAstExpr(mark, JLAstExpr.Data.setstatic(
                                    ownercls.toAstType(mark), name, astValexpr)),
                                expectedType)
                        } else {
                            solveExpression(
                                JLAstExpr(mark, JLAstExpr.Data.setfield(
                                    JLAstExpr(mark, JLAstExpr.Data.this()), name, astValexpr)),
                                expectedType)
                        }
                    } else {
                        throw JLError("Variable " + name + " not found", [mark])
                    }
                }
            }
            case augvar(name, operator, astValexpr) = {
                val nullableInstanceFieldref: Nullable[JLIRFieldRef] = {
                    if lctx.getLocalOrNull(name).isPresent() {
                        null
                    } else {
                        val ownercls = lctx.thisClass
                        if null(fieldref) = ownercls.getFieldRefOrNull(name) {
                            if fieldref.field.isStatic() {
                                null
                            } else {
                                null(fieldref)
                            }
                        } else {
                            null
                        }
                    }
                }
                if null(fieldref) = nullableInstanceFieldref {
                    if (fieldref.field.type == JLType.int() and
                            operator == JLAstExpr.Operator.add()) {
                        # Because of how common this is, I just want to support this special
                        # case now
                        val irThis = solveExpression(
                            JLAstExpr(mark, JLAstExpr.Data.this()), null)
                        val valexpr = solveExpression(astValexpr, null(JLType.int()))
                        JLIRExpr(mark, JLType.void(), JLIRExpr.Data.iaugfield(
                            fieldref, irThis, valexpr))
                    } else {
                        throw JLError("TODO augvar instance field " + operator, [mark])
                    }
                } else {
                    # As long as thte target is not an instance field, we should
                    # be working with a local variable or a static field, and
                    # just expanding (x <op>= y) to (x = x <op> y) should
                    # be fine
                    solveExpression(
                        JLAstExpr(mark, JLAstExpr.Data.setvar(
                            name,
                            JLAstExpr(mark, JLAstExpr.Data.operation(operator, [
                                JLAstExpr(mark, JLAstExpr.Data.getvar(name)),
                                astValexpr])))),
                        expectedType)
                }
            }
            case declvar(astLocal) = {
                val (variableType, irInit) = {
                    if astLocal.type.isPresent() {
                        val type = lctx.solveFieldType(astLocal.type.get())
                        val init = solveExpression(astLocal.init.get(), null(type))
                        (type, init)
                    } else {
                        val init = solveExpression(astLocal.init.get(), null)
                        (init.type, init)
                    }
                }
                val local = lctx.newLocal(
                    mark, astLocal.modifiers, astLocal.name, variableType)
                JLIRExpr(mark, JLType.void(), JLIRExpr.Data.declarelocal(local, irInit))
            }
            case this() = {
                if lctx.thisMethod.isStatic() {
                    throw JLError(
                        "'this' cannot be used in a static context (in method " +
                        lctx.thisMethod.name +
                        ")",
                        [mark])
                } else {
                    JLIRExpr(mark, JLType.klass(lctx.thisClass), JLIRExpr.Data.getlocal(
                        lctx.getLocalOrNull("this").get()))
                }
            }
            case list(astArgs) = {
                var nullableInnerType = if null(etype) = expectedType {
                    when etype {
                        case array(it) = null(it)
                        else = null
                    }
                } else { null }
                val irArgs: List[JLIRExpr] = []
                for astArg in astArgs {
                    val irArg = solveExpression(astArg, nullableInnerType)
                    if nullableInnerType.isEmpty() {
                        nullableInnerType = null(irArg.type)
                    }
                    irArgs.add(irArg)
                }
                val innerType = if null(it) = nullableInnerType {
                    it
                } else {
                    throw JLError("Could not infer list type", [mark])
                }
                val listClass = lctx.getListClass(mark, innerType)
                val listType = JLType.klass(listClass)
                val methodref = listClass.getMethodRef(mark, "fromArray")
                val fromArrayArgs = checkMethodArgs(true, mark, methodref, [Default()], [
                    JLIRExpr(
                        mark,
                        JLType.array(innerType),
                        JLIRExpr.Data.array(irArgs))
                ])
                JLIRExpr(mark, listType, JLIRExpr.Data.call(methodref, fromArrayArgs))
            }
            case if_(astCond, astBody, nullableOther) = {
                val irCond = solveTruthyCoercedExpression(astCond)
                if null(astOther) = nullableOther {
                    val irBody = solveExpression(astBody, expectedType)
                    val irOther = solveExpression(astOther, null(irBody.type))
                    JLIRExpr(mark, irBody.type, JLIRExpr.Data.if_(irCond, irBody, irOther))
                } else {
                    val irBody = solveVoidExpression(astBody)
                    JLIRExpr(mark, JLType.void(), JLIRExpr.Data.if_(
                        irCond,
                        irBody,
                        JLIRExpr(mark, JLType.void(), JLIRExpr.Data.void())))
                }
            }
            case while_(astCond, astBody) = {
                val irCond = solveTruthyCoercedExpression(astCond)
                val irBody = solveVoidExpression(astBody)
                JLIRExpr(mark, JLType.void(), JLIRExpr.Data.while_(
                    irCond, irBody))
            }
            case throw_(astExcExpr) = {
                val baseExceptionType = lctx.getClassTypeByQualifiedName(mark, "jl1.Exception")
                val irExcExpr = solveExpression(astExcExpr, null(baseExceptionType))
                JLIRExpr(mark, JLType.noreturn(), JLIRExpr.Data.throw_(irExcExpr))
            }
            case try_(astBody, astEntries, fin) = {
                val irBody = solveExpression(astBody, expectedType)
                val irEntries: List[Tuple[JLIRLocal, JLIRClass, JLIRExpr]] = []
                for (varname, astCls, astCatchBody) in astEntries {
                    lctx.pushScope()
                    val catchClass = lctx.solveClass(astCls)
                    val catchType = JLType.klass(catchClass)
                    val local = lctx.newLocal(mark, [], varname, catchType)
                    val catchBody = solveExpression(astCatchBody, expectedType)
                    irEntries.add((local, catchClass, catchBody))
                    lctx.popScope()
                }
                val tc = JLIRExpr(mark, irBody.type, JLIRExpr.Data.trycatch(irBody, irEntries))
                if null(f) = fin {
                    val irFin = solveVoidExpression(f)
                    JLIRExpr(mark, irBody.type, JLIRExpr.Data.tryfinally(
                        if astEntries.isEmpty() { irBody } else { tc },
                        irFin))
                } else {
                    if not irEntries {
                        throw JLError(
                            "try must have either at least one catch clause or a finally clause",
                            [mark])
                    }
                    tc
                }
            }
            case classicFor(astInit, astCond, astIncr, astBody) = {
                val ainit = (
                    if null(ainit) = astInit {
                        ainit
                    } else {
                        JLAstExpr(mark, JLAstExpr.Data.block([]))
                    })
                val acond = (
                    if null(acond) = astCond {
                        acond
                    } else {
                        JLAstExpr(mark, JLAstExpr.Data.bool(true))
                    })
                val aincr = (
                    if null(aincr) = astIncr {
                        aincr
                    } else {
                        JLAstExpr(mark, JLAstExpr.Data.block([]))
                    })
                solveVoidExpression(JLAstExpr(mark, JLAstExpr.Data.block([
                    ainit,
                    JLAstExpr(mark, JLAstExpr.Data.while_(acond,
                        JLAstExpr(mark, JLAstExpr.Data.block([astBody, aincr]))
                    ))
                ])))
            }
            case for_(name, container, body) = {
                throw JLError("TODO: solve expression for_", [mark])
            }
            case operation(operator, astArgs) = {
                when operator {
                    case logicalNot = {
                        Assert.equal(astArgs.size(), 1)
                        val irInner = solveTruthyCoercedExpression(astArgs[0])
                        JLIRExpr(mark, JLType.bool(), JLIRExpr.Data.not_(irInner))
                    }
                    case logicalAnd = {
                        val irArgs = astArgs.map(astArg -> solveTruthyCoercedExpression(astArg))
                        JLIRExpr(mark, JLType.bool(), JLIRExpr.Data.and_(irArgs))
                    }
                    case logicalOr = {
                        val irArgs = astArgs.map(astArg -> solveTruthyCoercedExpression(astArg))
                        JLIRExpr(mark, JLType.bool(), JLIRExpr.Data.or_(irArgs))
                    }
                    else = {
                        val irArg0 = solveExpression(astArgs[0], null)
                        val nullableIrExpr = when irArg0.type {
                            case int() = {
                                if null(irOp) = homogeneousIntOps.getOrNull(operator) {
                                    null(handleHomogeneousOps(mark, irOp, irArg0, astArgs))
                                } else if null(irOp) = comparisonIntOps.getOrNull(operator) {
                                    null(handleCompareOps(mark, irOp, irArg0, astArgs))
                                } else if null(irOp) = homogeneousUnaryIntOps.getOrNull(operator) {
                                    null(handleHomogeneousUnaryOp(mark, irOp, irArg0, astArgs))
                                } else {
                                    null
                                }
                            }
                            case double() = {
                                if null(irOp) = homogeneousDoubleOps.getOrNull(operator) {
                                    null(handleHomogeneousOps(mark, irOp, irArg0, astArgs))
                                } else {
                                    null
                                }
                            }
                            case klass(argcls) = switch argcls.name {
                                case "java.lang.String" = when operator {
                                    case add = null(handleStringOps(
                                        mark, JLIRExpr.Operator.strcat(), irArg0, astArgs))
                                    else = null
                                }
                                else = null
                            }
                            else = null
                        }
                        if null(irExpr) = nullableIrExpr {
                            irExpr
                        } else {
                            var negate = false
                            val methodName: String = when operator {
                                case logicalNot = throw Error("FUBAR")
                                case logicalAnd = throw Error("FUBAR")
                                case logicalOr = throw Error("FUBAR")
                                case add = "__add"
                                case sub = "__sub"
                                case mul = "__mul"
                                case div = "__div"
                                case rem = "__rem"
                                case and_ = "__and"
                                case or_ = "__or"
                                case xor = "__xor"
                                case shl = "__shl"
                                case shr = "__shr"
                                case shru = "__shru"
                                case neg = "__neg"
                                case pow = "__pow"
                                case lt = "__lt"
                                case le = "__le"
                                case gt = "__gt"
                                case ge = "__ge"
                                case eq = "__eq"
                                case ne = { negate = true; "__eq" }
                                case getitem = "__getitem"
                                case setitem = "__setitem"
                                case slice = "__slice"
                            }
                            if operator in JLParser.combineOperators {
                                var irExpr = irArg0
                                for i = 1; i < astArgs.size(); i++ {
                                    # WARNING: use of dummy entry with astArgs[0]
                                    irExpr = handleInstanceMethod(
                                        mark,
                                        expectedType,
                                        methodName,
                                        [astArgs[0], astArgs[i]],
                                        irExpr)
                                    if negate {
                                        irExpr = JLIRExpr(
                                            mark, JLType.bool(), JLIRExpr.Data.not_(irExpr))
                                    }
                                }
                                irExpr
                            } else {
                                val irExpr = handleInstanceMethod(
                                    mark, expectedType, methodName, astArgs, irArg0)
                                if negate {
                                    JLIRExpr(mark, JLType.bool(), JLIRExpr.Data.not_(irExpr))
                                } else {
                                    irExpr
                                }
                            }
                        }
                    }
                }
            }
            case meta(metaExpr) = {
                val metaSolver = JLIRMetaSolver(lctx, self)
                metaSolver.solveExpr(metaExpr, expectedType)
            }
            case javacall(kind, astReturnType, className, methodName, descriptor, astArgs) = {
                val returnType = lctx.solveType(astReturnType)
                val args = astArgs.map(astArg -> solveExpression(astArg, null))
                JLIRExpr(mark, returnType, JLIRExpr.Data.javacall(
                    kind, className, methodName, descriptor, args))
            }
            case javanew(astReturnType, className, descriptor, astArgs) = {
                val returnType = lctx.solveType(astReturnType)
                val args = astArgs.map(astArg -> solveExpression(astArg, null))
                JLIRExpr(mark, returnType, JLIRExpr.Data.javanew(
                    className, descriptor, args))
            }
            case initfield(fieldName, astValexpr) = {
                val fieldref = lctx.thisClass.getFieldRef(mark, fieldName)
                val valexpr = solveExpression(astValexpr, null(fieldref.field.type))
                JLIRExpr(mark, JLType.void(), JLIRExpr.Data.initfield(fieldref, valexpr))
            }
        }
        irExpr
    }

    private def checkMethodArgs(
            self,
            static_: Bool,
            mark: JLMark,
            methodref: JLIRMethodRef,
            astArgs: List[JLAstExpr],
            irArgs: List[JLIRExpr]): List[JLIRExpr] {
        if static_ {
            if not methodref.method.isStatic() {
                throw JLError("" + methodref + " is non-static", [mark])
            }
        } else {
            if methodref.method.isStatic() {
                throw JLError("" + methodref + " is static", [mark])
            }
        }
        val argc = methodref.method.parameters.size()
        if argc != astArgs.size() {
            throw JLError(
                "" + methodref +
                " expects " + argc +
                " args but got " + astArgs.size(), [mark])
        }
        for i = 0; i < irArgs.size(); i++ {
            irArgs[i] = checkTypeAndCast(methodref.method.parameters[i].type, irArgs[i])
        }
        for i = irArgs.size(); i < argc; i++ {
            irArgs.add(solveExpression(
                astArgs[i], null(methodref.method.parameters[i].type)))
        }
        irArgs
    }

    private def primitiveObjCast(self, expr: JLIRExpr): JLIRExpr {
        val objType = getObjectType()
        val mark = expr.mark
        when expr.type {
            case int() = callStaticJavaMethod(
                mark, "java/lang/Integer", "valueOf", "(I)Ljava/lang/Integer;", objType, [expr])
            case long() = callStaticJavaMethod(
                mark, "java/lang/Long", "valueOf", "(J)Ljava/lang/Long;", objType, [expr])
            case float() = callStaticJavaMethod(
                mark, "java/lang/Float", "valueOf", "(F)Ljava/lang/Float;", objType, [expr])
            case double() = callStaticJavaMethod(
                mark, "java/lang/Double", "valueOf", "(D)Ljava/lang/Double;", objType, [expr])
            else = throw JLError("TODO primitiveObjCast " + expr.type, [expr.mark])
        }
    }

    private def checkTypeAndCast(self, type: JLType, expr: JLIRExpr): JLIRExpr {
        if type == expr.type {
            expr
        } else {
            val nullableExpr = when type {
                case void = null(voidify(expr))
                case klass(expectedClass) = {
                    when expr.type {
                        case int = if type.isObject() { null(primitiveObjCast(expr)) } else { null }
                        case long = if type.isObject() { null(primitiveObjCast(expr)) } else { null }
                        case float = if type.isObject() { null(primitiveObjCast(expr)) } else { null }
                        case double = if type.isObject() { null(primitiveObjCast(expr)) } else { null }
                        case klass(actualClass) = {
                            val mark = expr.mark
                            if actualClass.extends(expectedClass) {
                                null(JLIRExpr(mark, type, JLIRExpr.Data.upcast(expr)))
                            } else if expectedClass.extends(actualClass) {
                                null(JLIRExpr(mark, type, JLIRExpr.Data.downcast(expr)))
                            } else {
                                null
                            }
                        }
                        else = null
                    }
                }
                else = null
            }
            if null(newExpr) = nullableExpr {
                newExpr
            } else {
                throw JLError("Expected " + type + " but got " + expr.type, [expr.mark])
            }
        }
    }

    private def checkArgc(self, mark: JLMark, astArgs: List[JLAstExpr], argc: Int) {
        if astArgs.size() != argc {
            throw JLError("Expected " + argc + " but got " + astArgs.size(), [mark])
        }
    }

    private def handleInstanceMethod(
            self,
            mark: JLMark,
            expectedType: Nullable[JLType],
            methodName: String,
            astArgs: List[JLAstExpr],
            irOwner: JLIRExpr): JLIRExpr {
        when irOwner.type {
            case array(innertype) = {
                switch methodName {
                    case "size" = {
                        checkArgc(mark, astArgs, 1)
                        JLIRExpr(mark, JLType.int(), JLIRExpr.Data.operation(
                            JLIRExpr.Operator.arraylen(),
                            [irOwner]))
                    }
                    case "realloc" = {
                        checkArgc(mark, astArgs, 2)
                        val newlen = solveExpression(astArgs[1], null(JLType.int()))
                        JLIRExpr(mark, irOwner.type, JLIRExpr.Data.operation(
                            JLIRExpr.Operator.arrayrealloc(),
                            [irOwner, newlen]))
                    }
                    case "clear" = {
                        checkArgc(mark, astArgs, 2)
                        val index = solveExpression(astArgs[1], null(JLType.int()))
                        JLIRExpr(mark, JLType.void(), JLIRExpr.Data.operation(
                            JLIRExpr.Operator.arrayclear(), [irOwner, index]))
                    }
                    case "__getitem" = {
                        checkArgc(mark, astArgs, 2)
                        val index = solveExpression(astArgs[1], null(JLType.int()))
                        JLIRExpr(mark, innertype, JLIRExpr.Data.operation(
                            JLIRExpr.Operator.arrayget(), [irOwner, index]))
                    }
                    case "__setitem" = {
                        checkArgc(mark, astArgs, 3)
                        val index = solveExpression(astArgs[1], null(JLType.int()))
                        val value = solveExpression(astArgs[2], null(innertype))
                        JLIRExpr(mark, JLType.void(), JLIRExpr.Data.operation(
                            JLIRExpr.Operator.arrayset(), [irOwner, index, value]))
                    }
                    else = throw JLError(
                        "Method " + methodName + " not found for " + irOwner.type, [mark])
                }
            }
            case klass(ownercls) = {
                if ownercls.name == "java.lang.String" {
                    switch methodName {
                        case "size" = {
                            checkArgc(mark, astArgs, 1)
                            JLIRExpr(mark, JLType.int(), JLIRExpr.Data.javacall(
                                "virtual",
                                "java/lang/String",
                                "length",
                                "()I",
                                [irOwner]))
                        }
                        case "__eq" = {
                            checkArgc(mark, astArgs, 2)
                            val other = solveExpression(astArgs[1], null(irOwner.type))
                            JLIRExpr(mark, JLType.bool(), JLIRExpr.Data.javacall(
                                "virtual",
                                "java/lang/String",
                                "equals",
                                "(Ljava/lang/Object;)Z",
                                [irOwner, other]))
                        }
                        else = throw JLError(
                            "Method " + methodName + " not found for String", [mark])
                    }
                } else {
                    if null(methodref) = ownercls.getMethodRefOrNull(methodName) {
                        val irArgs = checkMethodArgs(
                            false, mark, methodref, astArgs, [irOwner])
                        JLIRExpr(mark, methodref.method.returnType, JLIRExpr.Data.call(
                            methodref, irArgs))
                    } else if null(methodTemplate) = ownercls.getMethodTemplateOrNull(
                            methodName) {
                        throw JLError("TODO template instance method call", [mark])
                    } else {
                        throw JLError("Method " + methodName + " not found", [mark])
                    }
                }
            }
            else = throw JLError(
                "" + irOwner.type + " values do not have methods", [mark])
        }
    }

    ## solve an operation where all inputs and the output have the same type.
    private def handleHomogeneousOps(
            self,
            mark: JLMark,
            op: JLIRExpr.Operator,
            irArg0: JLIRExpr,
            astArgs: List[JLAstExpr]): JLIRExpr {
        val irArgs: List[JLIRExpr] = [irArg0]
        for i = 1; i < astArgs.size(); i++ {
            irArgs.add(solveExpression(
                astArgs[i], null(irArg0.type)))
        }
        JLIRExpr(mark, irArg0.type, JLIRExpr.Data.operation(op, irArgs))
    }

    ## solve an operation where all inputs and the output have the same type.
    private def handleHomogeneousUnaryOp(
            self,
            mark: JLMark,
            op: JLIRExpr.Operator,
            irArg0: JLIRExpr,
            astArgs: List[JLAstExpr]): JLIRExpr {
        if astArgs.size() != 1 {
            throw JLError("" + op + " exepcts exactly one argument", [mark])
        }
        JLIRExpr(mark, irArg0.type, JLIRExpr.Data.operation(op, [irArg0]))
    }

    private def handleCompareOps(
            self,
            mark: JLMark,
            op: JLIRExpr.Operator,
            irArg0: JLIRExpr,
            astArgs: List[JLAstExpr]): JLIRExpr {
        if astArgs.size() != 2 {
            throw JLError("" + op + " operator is non-associative and cannot be chained", [mark])
        }
        val irArgs: List[JLIRExpr] = [irArg0]
        for i = 1; i < astArgs.size(); i++ {
            irArgs.add(solveExpression(
                astArgs[i], null(irArg0.type)))
        }
        JLIRExpr(mark, JLType.bool(), JLIRExpr.Data.operation(op, irArgs))
    }

    private def handleStringOps(
            self,
            mark: JLMark,
            op: JLIRExpr.Operator,
            irArg0: JLIRExpr,
            astArgs: List[JLAstExpr]): JLIRExpr {
        val irArgs: List[JLIRExpr] = [irArg0]
        for i = 1; i < astArgs.size(); i++ {
            irArgs.add(solveStringCoercedExpression(astArgs[i]))
        }
        JLIRExpr(mark, irArg0.type, JLIRExpr.Data.operation(op, irArgs))
    }
}
