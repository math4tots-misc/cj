package cjx.jl1

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
            if etype != irExpr.type {
                if etype.isVoid() {
                    voidify(irExpr)
                } else if etype.isObject() {
                    coerceToObject(irExpr)
                } else {
                    throw JLError("Expected " + etype + " but got " + irExpr.type, [astExpr.mark])
                }
            } else {
                irExpr
            }
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

    def coerceToObject(self, irExpr: JLIRExpr): JLIRExpr {
        val mark = irExpr.mark
        val objType = getObjectType()
        when irExpr.type {
            case int() = callStaticJavaMethod(
                mark, "java/lang/Integer", "valueOf", "(I)Ljava/lang/Integer;", objType, [irExpr])
            case long() = callStaticJavaMethod(
                mark, "java/lang/Long", "valueOf", "(J)Ljava/lang/Long;", objType, [irExpr])
            case float() = callStaticJavaMethod(
                mark, "java/lang/Float", "valueOf", "(F)Ljava/lang/Float;", objType, [irExpr])
            case double() = callStaticJavaMethod(
                mark, "java/lang/Double", "valueOf", "(D)Ljava/lang/Double;", objType, [irExpr])
            case array(inner) = irExpr
            case klass(cls) = irExpr
            else = throw JLError("Expected Object but got " + irExpr.type, [mark])
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
        JLIRExpr(mark, returnType, JLIRExpr.Data.calljava(
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
        JLIRExpr(mark, returnType, JLIRExpr.Data.calljava(
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
        JLIRExpr(mark, returnType, JLIRExpr.Data.calljava(
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
                val ownercls = lctx.solveClass(astOwnerType)
                if ownercls.isInterface() or ownercls.isAbstract() {
                    throw JLError("new cannot be used with interface or abstract classes", [mark])
                }
                val methodref = ownercls.getMethodRef(mark, "<init>")
                val irArgs = checkMethodArgs(false, mark, methodref, null, astArgs)
                JLIRExpr(mark, JLType.klass(ownercls), JLIRExpr.Data.callnew(methodref, irArgs))
            }
            case callstatic(astOwnerType, methodName, astArgs) = {
                val ownercls = lctx.solveClass(astOwnerType)
                val methodref = ownercls.getMethodRef(mark, methodName)
                val irArgs = checkMethodArgs(true, mark, methodref, null, astArgs)
                JLIRExpr(mark, methodref.method.returnType, JLIRExpr.Data.call(methodref, irArgs))
            }
            case callinstance(astOwner, methodName, astArgs) = {
                val irOwner = solveExpression(astOwner, null)
                val ownercls = when irOwner.type {
                    case klass(ownercls) = ownercls
                    else = throw JLError(
                        "" + irOwner.type + " values do not have methods", [mark])
                }
                val methodref = ownercls.getMethodRef(mark, methodName)
                val irArgs = checkMethodArgs(false, mark, methodref, null(irOwner), astArgs)
                JLIRExpr(mark, methodref.method.returnType, JLIRExpr.Data.call(methodref, irArgs))
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
                    solveExpression(JLAstExpr(mark, JLAstExpr.Data.callinstance(
                        JLAstExpr(mark, JLAstExpr.Data.this()),
                        methodName,
                        astArgs)), expectedType)
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
                JLIRExpr(mark, fieldref.field.type, JLIRExpr.Data.setfield(
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
            case operation(operator, astArgs) = {
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
                        case "java.lang.String" = null(handleStringOps(
                            mark, JLIRExpr.Operator.strcat(), irArg0, astArgs))
                        else = null
                    }
                    else = null
                }
                if null(irExpr) = nullableIrExpr {
                    irExpr
                } else {
                    throw JLError("" + operator + " not supported for " + irArg0.type, [mark])
                }
            }
            case calljava(kind, astReturnType, className, methodName, descriptor, astArgs) = {
                val returnType = lctx.solveType(astReturnType)
                val args = astArgs.map(astArg -> solveExpression(astArg, null))
                JLIRExpr(mark, returnType, JLIRExpr.Data.calljava(
                    kind, className, methodName, descriptor, args))
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
            nullableIrOwner: Nullable[JLIRExpr],
            astArgs: List[JLAstExpr]): List[JLIRExpr] {
        if static_ {
            if not methodref.method.isStatic() {
                throw JLError("" + methodref + " is non-static", [mark])
            }
            val argc = methodref.method.parameters.size()
            if argc != astArgs.size() {
                throw JLError(
                    "" + methodref +
                    " expects " + argc +
                    " args but got " + astArgs.size(), [mark])
            }
            val irArgs: List[JLIRExpr] = []
            for i = 0; i < argc; i++ {
                irArgs.add(solveExpression(
                    astArgs[i], null(methodref.method.parameters[i].type)))
            }
            irArgs
        } else {
            if methodref.method.isStatic() {
                throw JLError("" + methodref + " is static", [mark])
            }
            val argc = methodref.method.parameters.size() - 1
            if argc != astArgs.size() {
                throw JLError(
                    "" + methodref +
                    " expects " + argc +
                    " args but got " + astArgs.size(), [mark])
            }
            val irArgs: List[JLIRExpr] = if null(irOwner) = nullableIrOwner {
                [irOwner] } else { [] }
            for i = 1; i <= argc; i++ {
                irArgs.add(solveExpression(
                    astArgs[i - 1], null(methodref.method.parameters[i].type)))
            }
            irArgs
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
