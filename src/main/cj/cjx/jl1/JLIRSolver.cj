package cjx.jl1

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
class JLIRSolver {
    static val builtinTypeMap: Map[String, String] = Map(
        "Object": "java.lang.Object",
        "String": "java.lang.String",
    )

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

    static val homogeneousDoubleOps: Map[JLAstExpr.Operator, JLIRExpr.Operator] = Map(
        JLAstExpr.Operator.add(): JLIRExpr.Operator.dadd(),
    )

    val ctx: JLContext

    def solve(self, files: List[JLAstFile]) {
        pass0(files)
        pass1(files)
        pass2(files)
        pass3(files)
    }

    ## init JLIRClass objects
    def pass0(self, files: List[JLAstFile]) {
        walkClasses(ctx, files, (name, astcls, lctx) -> {
            ctx.classMap[name] = JLIRClass(
                astcls.mark,
                astcls.modifiers,
                astcls.isInterface(),
                name)
        })
    }

    ## Resolve interface types
    def pass1(self, files: List[JLAstFile]) {
        walkClasses(ctx, files, (name, astcls, lctx) -> {
            val ircls = ctx.classMap[name]
            for astInterface in astcls.interfaces {
                val irInterface = lctx.solveInterfaceType(astInterface)
                if not irInterface.isInterface() {
                    throw JLError("Expected interface", [astInterface.mark])
                }
                ircls.interfaces.add(irInterface)
            }
        })
    }

    ## Resolve method and field types
    def pass2(self, files: List[JLAstFile]) {
        walkClasses(ctx, files, (clsname, astcls, lctx) -> {
            val ircls = ctx.classMap[clsname]
            val thisType = JLType.klass(ircls)
            for astMember in astcls.members {
                when astMember {
                    case klass(innercls) = ()
                    case field(astField) = {
                        val irField = JLIRField(
                            astField.mark,
                            astField.comment,
                            astField.modifiers,
                            astField.name,
                            lctx.solveFieldType(astField.type))
                        ircls.addField(irField)
                    }
                    case method(astMethod) = {
                        val parameters: List[JLIRLocal] = []
                        for astLocal in astMethod.parameters {
                            Assert.that(astLocal.init.isEmpty())
                            val irLocal = JLIRLocal(
                                astLocal.mark,
                                parameters.size(),
                                astLocal.modifiers,
                                astLocal.name,
                                if astLocal.name == "this" {
                                    Assert.that(astLocal.type.isEmpty())
                                    thisType
                                } else {
                                    lctx.solveFieldType(astLocal.type.get())
                                })
                            parameters.add(irLocal)
                        }
                        val irMethod = JLIRMethod(
                            astMethod.mark,
                            astMethod.comment,
                            astMethod.modifiers,
                            astMethod.name,
                            parameters,
                            lctx.solveType(astMethod.returnType),
                            parameters.clone())
                        ircls.addMethod(irMethod)
                    }
                }
            }
        })
    }

    ## Resolve expressions
    def pass3(self, files: List[JLAstFile]) {
        walkClasses(ctx, files, (clsname, astcls, lctx) -> {
            val ircls = ctx.classMap[clsname]
            val thisType = JLType.klass(ircls)
            for astMember in astcls.members {
                when astMember {
                    case klass(innercls) = ()
                    case field(astField) = ()
                    case method(astMethod) = {
                        if astMethod.body.isPresent() {
                            val irMethod = ircls.getDeclaredMethod(astMethod.name)
                            val astBody = astMethod.body.get()
                            val mlctx = JLIRLocalContext(
                                lctx.ctx,
                                lctx.className,
                                lctx.typeMap,
                                astMethod.name)
                            val irBody = solveExpression(
                                mlctx, astBody, null(irMethod.returnType))
                            irMethod.body = null(irBody)
                        }
                    }
                }
            }
        })
    }

    def solveExpression(
            self,
            lctx: JLIRLocalContext,
            astExpr: JLAstExpr,
            expectedType: Nullable[JLType]): JLIRExpr {
        val irExpr = solveExpressionUnchecked(lctx, astExpr, expectedType)

        if null(etype) = expectedType {
            if not etype.isVoid() and etype != irExpr.type {
                if etype.isObject() {
                    coerceToObject(lctx, irExpr)
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

    def solveTruthyCoercedExpression(
            self,
            lctx: JLIRLocalContext,
            astExpr: JLAstExpr): JLIRExpr {
        val mark = astExpr.mark
        val irExpr = solveExpressionUnchecked(lctx, astExpr, null)
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
            lctx: JLIRLocalContext,
            astExpr: JLAstExpr): JLIRExpr {
        val mark = astExpr.mark
        val irExpr = solveExpressionUnchecked(lctx, astExpr, null)
        val strtype = ctx.getClassType(mark, "java.lang.String")

        val nullableIrExpr: Nullable[JLIRExpr] = when irExpr.type {
            case void() = null
            case bool() = null(callStaticJavaMethod(
                mark, "java/lang/Boolean", "toString", "(Z)Ljava/lang/String;", strtype, [irExpr]))
            case char() = null
            case int() = null(callStaticJavaMethod(
                mark, "java/lang/Integer", "toString", "(I)Ljava/lang/String;", strtype, [irExpr]))
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

    def coerceToObject(self, lctx: JLIRLocalContext, irExpr: JLIRExpr): JLIRExpr {
        val mark = irExpr.mark
        val objType = ctx.getClassType(mark, "java.lang.Object")
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

    def solveExpressionUnchecked(
            self,
            lctx: JLIRLocalContext,
            astExpr: JLAstExpr,
            expectedType: Nullable[JLType]): JLIRExpr {

        val mark = astExpr.mark

        val irExpr: JLIRExpr = when astExpr.data {
            case bool(x) = JLIRExpr(mark, JLType.bool(), JLIRExpr.Data.bool(x))
            case char(x) = JLIRExpr(mark, JLType.char(), JLIRExpr.Data.char(x))
            case int(x) = JLIRExpr(mark, JLType.int(), JLIRExpr.Data.int(x))
            case double(x) = JLIRExpr(mark, JLType.double(), JLIRExpr.Data.double(x))
            case string(x) = JLIRExpr(
                mark, ctx.getClassType(mark, "java.lang.String"), JLIRExpr.Data.string(x))
            case block(astExprs) = {
                if astExprs {
                    val irExprs: List[JLIRExpr] = []

                    lctx.pushScope()
                    for i = 0; i + 1 < astExprs.size(); i++ {
                        irExprs.add(solveExpression(lctx, astExprs[i], null(JLType.void())))
                    }
                    irExprs.add(solveExpression(lctx, astExprs.last(), expectedType))
                    lctx.popScope()

                    JLIRExpr(mark, irExprs.last().type, JLIRExpr.Data.block(irExprs))
                } else {
                    JLIRExpr(mark, JLType.void(), JLIRExpr.Data.void())
                }
            }
            case callstatic(ownerName, methodName, astArgs) = {
                val ownercls = lctx.getClass(mark, ownerName)
                val methodref = ownercls.getMethodRef(mark, methodName)
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
                        lctx, astArgs[i], null(methodref.method.parameters[i].type)))
                }
                JLIRExpr(mark, methodref.method.returnType, JLIRExpr.Data.call(methodref, irArgs))
            }
            case callinstance(astOwner, methodName, astArgs) = {
                val irOwner = solveExpression(lctx, astOwner, null)
                val ownercls = when irOwner.type {
                    case klass(ownercls) = ownercls
                    else = {
                        throw JLError("" + irOwner.type + " values do not have methods", [mark])
                    }
                }
                val methodref = ownercls.getMethodRef(mark, methodName)
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
                val irArgs: List[JLIRExpr] = [irOwner]
                for i = 1; i <= argc; i++ {
                    irArgs.add(solveExpression(
                        lctx, astArgs[i - 1], null(methodref.method.parameters[i].type)))
                }
                JLIRExpr(mark, methodref.method.returnType, JLIRExpr.Data.call(methodref, irArgs))
            }
            case callname(methodName, astArgs) = {
                # syntactic sugar for callstatic or callinstance
                val ownercls = lctx.thisClass
                val methodref = ownercls.getMethodRef(mark, methodName)
                if methodref.method.isStatic() {
                    solveExpression(lctx, JLAstExpr(mark, JLAstExpr.Data.callstatic(
                        ownercls.name,
                        methodName,
                        astArgs)), expectedType)
                } else {
                    solveExpression(lctx, JLAstExpr(mark, JLAstExpr.Data.callinstance(
                        JLAstExpr(mark, JLAstExpr.Data.this()),
                        methodName,
                        astArgs)), expectedType)
                }
            }
            case getstatic(clsname, fieldName) = {
                val ownercls = lctx.getClass(mark, clsname)
                val fieldref = ownercls.getFieldRef(mark, fieldName)
                if not fieldref.field.isStatic() {
                    throw JLError("" + fieldref + " is non-static", [mark])
                }
                JLIRExpr(mark, fieldref.field.type, JLIRExpr.Data.getstatic(fieldref))
            }
            case setstatic(clsname, fieldName, astValexpr) = {
                val ownercls = lctx.getClass(mark, clsname)
                val fieldref = ownercls.getFieldRef(mark, fieldName)
                if not fieldref.field.isStatic() {
                    throw JLError("" + fieldref + " is non-static", [mark])
                }
                if not fieldref.field.isMutable() {
                    throw JLError("" + fieldref + " is not mutable", [mark])
                }
                val valexpr = solveExpression(lctx, astValexpr, null(fieldref.field.type))
                JLIRExpr(mark, JLType.void(), JLIRExpr.Data.setstatic(fieldref, valexpr))
            }
            case getfield(astOwner, fieldName) = {
                val irOwner = solveExpression(lctx, astOwner, null)
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
                val irOwner = solveExpression(lctx, astOwner, null)
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
                val valexpr = solveExpression(lctx, astValexpr, null(fieldref.field.type))
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
                                lctx,
                                JLAstExpr(mark, JLAstExpr.Data.getstatic(ownercls.name, name)),
                                expectedType)
                        } else {
                            solveExpression(
                                lctx,
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
                    val valexpr = solveExpression(lctx, astValexpr, null(local.type))
                    JLIRExpr(mark, JLType.void(), JLIRExpr.Data.setlocal(local, valexpr))
                } else {
                    val ownercls = lctx.thisClass
                    if null(fieldref) = ownercls.getFieldRefOrNull(name) {
                        if fieldref.field.isStatic() {
                            solveExpression(
                                lctx,
                                JLAstExpr(mark, JLAstExpr.Data.setstatic(
                                    ownercls.name, name, astValexpr)),
                                expectedType)
                        } else {
                            solveExpression(
                                lctx,
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
                        val init = solveExpression(lctx, astLocal.init.get(), null(type))
                        (type, init)
                    } else {
                        val init = solveExpression(lctx, astLocal.init.get(), null)
                        (init.type, init)
                    }
                }
                val local = lctx.newLocal(
                    mark, astLocal.modifiers, astLocal.name, variableType)
                JLIRExpr(mark, JLType.void(), JLIRExpr.Data.declarelocal(local, irInit))
            }
            case this() = {
                if lctx.thisMethod.isStatic() {
                    throw JLError("'this' cannot be used in a static context", [mark])
                } else {
                    JLIRExpr(mark, JLType.klass(lctx.thisClass), JLIRExpr.Data.getlocal(
                        lctx.getLocalOrNull("this").get()))
                }
            }
            case if_(astCond, astBody, nullableOther) = {
                val irCond = solveTruthyCoercedExpression(lctx, astCond)
                if null(astOther) = nullableOther {
                    val irBody = solveExpression(lctx, astBody, expectedType)
                    val irOther = solveExpression(lctx, astOther, null(irBody.type))
                    JLIRExpr(mark, irBody.type, JLIRExpr.Data.if_(irCond, irBody, irOther))
                } else {
                    val irBody = solveExpression(lctx, astBody, null(JLType.void()))
                    JLIRExpr(mark, JLType.void(), JLIRExpr.Data.if_(
                        irCond,
                        irBody,
                        JLIRExpr(mark, JLType.void(), JLIRExpr.Data.void())))
                }
            }
            case operation(operator, astArgs) = {
                val irArg0 = solveExpression(lctx, astArgs[0], null)
                val nullableIrExpr = when irArg0.type {
                    case int() = {
                        if null(irOp) = homogeneousIntOps.getOrNull(operator) {
                            null(handleHomogeneousOps(mark, lctx, irOp, irArg0, astArgs))
                        } else {
                            null
                        }
                    }
                    case double() = {
                        if null(irOp) = homogeneousDoubleOps.getOrNull(operator) {
                            null(handleHomogeneousOps(mark, lctx, irOp, irArg0, astArgs))
                        } else {
                            null
                        }
                    }
                    case klass(argcls) = switch argcls.name {
                        case "java.lang.String" = null(handleStringOps(
                            mark, lctx, JLIRExpr.Operator.strcat(), irArg0, astArgs))
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
                val args = astArgs.map(astArg -> solveExpression(lctx, astArg, null))
                JLIRExpr(mark, returnType, JLIRExpr.Data.calljava(
                    kind, className, methodName, descriptor, args))
            }
        }
        irExpr
    }

    ## solve an operation where all inputs and the output have the same type.
    private def handleHomogeneousOps(
            self,
            mark: JLMark,
            lctx: JLIRLocalContext,
            op: JLIRExpr.Operator,
            irArg0: JLIRExpr,
            astArgs: List[JLAstExpr]): JLIRExpr {
        val irArgs: List[JLIRExpr] = [irArg0]
        for i = 1; i < astArgs.size(); i++ {
            irArgs.add(solveExpression(
                lctx, astArgs[i], null(irArg0.type)))
        }
        JLIRExpr(mark, irArg0.type, JLIRExpr.Data.operation(op, irArgs))
    }

    private def handleStringOps(
            self,
            mark: JLMark,
            lctx: JLIRLocalContext,
            op: JLIRExpr.Operator,
            irArg0: JLIRExpr,
            astArgs: List[JLAstExpr]): JLIRExpr {
        val irArgs: List[JLIRExpr] = [irArg0]
        for i = 1; i < astArgs.size(); i++ {
            irArgs.add(solveStringCoercedExpression(lctx, astArgs[i]))
        }
        JLIRExpr(mark, irArg0.type, JLIRExpr.Data.operation(op, irArgs))
    }

    private def qualifyClassName(file: JLAstFile, cls: JLAstClass): String = (
        file.packageName + "." + cls.shortName)

    private def qualifyInnerClassName(outerClassName: String, cls: JLAstClass): String =(
        outerClassName + "$" + cls.shortName)

    private def walkClasses(
            ctx: JLContext,
            files: List[JLAstFile],
            f: Fn[String, JLAstClass, JLIRLocalContext, Unit]) {
        for file in files {
            val typeMap = builtinTypeMap.clone()

            for imp in file.imports {
                typeMap[imp.alias] = imp.qualifiedName
            }
            for cls in file.classes {
                val name = qualifyClassName(file, cls)
                typeMap[cls.shortName] = name

                # allow use of fully qualified names in local contexts
                typeMap[name] = name

                for member in cls.members {
                    when member {
                        case klass(innercls) = {
                            val innerName = qualifyInnerClassName(name, innercls)
                            typeMap[innercls.shortName] = innerName
                            for innerMember in innercls.members {
                                when innerMember {
                                    case klass(innerInnercls) = {
                                        throw JLError(
                                            "inner classes cannot have inner classes",
                                            [innerInnercls.mark])
                                    }
                                    else = ()
                                }
                            }
                        }
                        else = ()
                    }
                }
            }

            for cls in file.classes {
                val name = qualifyClassName(file, cls)
                val lctx = JLIRLocalContext(ctx, name, typeMap, "")
                f.call(name, cls, lctx)
                for member in cls.members {
                    when member {
                        case klass(innercls) = {
                            val innerName = qualifyInnerClassName(name, innercls)
                            val innerLctx = JLIRLocalContext(ctx, innerName, typeMap, "")
                            f.call(innerName, innercls, innerLctx)
                        }
                        else = ()
                    }
                }
            }
        }
    }
}
