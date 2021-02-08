package cjx.jl1

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
                    for i = 0; i + 1 < astExprs.size(); i++ {
                        irExprs.add(solveExpression(lctx, astExprs[i], null(JLType.void())))
                    }
                    irExprs.add(solveExpression(lctx, astExprs.last(), expectedType))
                    JLIRExpr(mark, irExprs.last().type, JLIRExpr.Data.block(irExprs))
                } else {
                    JLIRExpr(mark, JLType.void(), JLIRExpr.Data.block([]))
                }
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
            case getstatic(clsname, fieldName) = {
                val ownercls = lctx.getClass(mark, clsname)
                val fieldref = ownercls.getFieldRef(mark, fieldName)
                JLIRExpr(mark, fieldref.field.type, JLIRExpr.Data.getstatic(fieldref))
            }
            else = throw JLError("TODO", [mark])
        }

        if null(etype) = expectedType {
            if not etype.isVoid() and etype != irExpr.type {
                throw JLError("Expected " + etype + " but got " + irExpr.type, [mark])
            }
        } else {
            # If a void type was not specifically requested, it's not allowed
            if irExpr.type.isVoid() {
                throw JLError("a void expression is not allowed here", [mark])
            }
        }
        irExpr
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
