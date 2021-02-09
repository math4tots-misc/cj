package cjx.jl1

import cjx.jl1.JLIRExpressionSolver
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
    val ctx: JLContext

    def solve(self, files: List[JLAstFile]) {
        pass0(files)
        pass1(files)
        pass2(files)
        pass3(files)
    }

    ## init JLIRClass objects
    def pass0(self, files: List[JLAstFile]) {
        walkClasses(ctx, files, (name, astfile, astcls, lctx) -> {
            if astcls.templateParameters {
                ctx.classTemplateMap[name] = (astfile, astcls)
            } else {
                ctx.newClass(
                    astcls.mark,
                    astcls.modifiers,
                    astcls.isInterface(),
                    name)
            }
        })
    }

    ## Resolve interface types
    def pass1(self, files: List[JLAstFile]) {
        walkClasses(ctx, files, (name, astfile, astcls, lctx) -> {
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
        walkClasses(ctx, files, (clsname, astfile, astcls, lctx) -> {
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
        walkClasses(ctx, files, (clsname, astfile, astcls, lctx) -> {
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
                                lctx.typeMap,
                                lctx.className,
                                astMethod.name)
                            val esolver = JLIRExpressionSolver(mlctx)
                            val irBody = esolver.solveExpression(
                                astBody, null(irMethod.returnType))
                            irMethod.body = null(irBody)
                        }
                    }
                }
            }
        })
    }

    private def walkClasses(
            ctx: JLContext,
            files: List[JLAstFile],
            f: Fn[String, JLAstFile, JLAstClass, JLIRLocalContext, Unit]) {
        for file in files {
            val typeMap = JLContext.buildTypeMap(file)
            for cls in file.classes {
                val name = JLContext.qualifyClassName(file, cls)
                val lctx = JLIRLocalContext(ctx, typeMap, name, "")
                f.call(name, file, cls, lctx)
                for member in cls.members {
                    when member {
                        case klass(innercls) = {
                            val innerName = JLContext.qualifyInnerClassName(name, innercls)
                            val innerLctx = JLIRLocalContext(ctx, typeMap, innerName, "")
                            f.call(innerName, file, innercls, innerLctx)
                        }
                        else = ()
                    }
                }
            }
        }
    }
}
