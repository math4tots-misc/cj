package cjx.jl1

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
                ircls.interfaces.add(lctx.solveInterfaceType(astInterface))
            }
        })
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
            val typeMap: Map[String, String] = Map()

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
                val lctx = JLIRLocalContext(ctx, name, typeMap)
                f.call(name, cls, lctx)
                for member in cls.members {
                    when member {
                        case klass(innercls) = {
                            val innerName = qualifyInnerClassName(name, innercls)
                            val innerLctx = JLIRLocalContext(ctx, innerName, typeMap)
                            f.call(innerName, innercls, innerLctx)
                        }
                        else = ()
                    }
                }
            }
        }
    }
}
