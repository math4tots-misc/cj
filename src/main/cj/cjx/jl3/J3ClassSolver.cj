package cjx.jl3

import cjx.jl1.JLAstTemplateArgument
import cjx.jl1.JLMark
import cjx.jl1.JLError
import cjx.jl3.J3Type
import cjx.jl1.JLAstType
import cjx.jl1.JLAstClass
import cjx.jl3.J3Class
import cjx.jl3.J3Data
import cjx.jl3.J3Solver

@derive(new)
class J3ClassSolver {
    val solver: J3Solver
    val cls: J3Class

    ## E.g. imports, template arguments
    val map: Map[String, J3Data]

    def initWithAst(self, astcls: JLAstClass) {
        solver.todo1(() -> {
            for astBase in astcls.bases {
                val irBase = solveType(astBase)
                when irBase {
                    case klass(baseClass) = {
                        if baseClass.isInterface() {
                            cls.interfaces.add(baseClass)
                        } else {
                            if null(otherSuperClass) = cls.superClass {
                                throw JLError(
                                    "Multiple base classes are not allowed (" +
                                    otherSuperClass +
                                    ", " +
                                    baseClass +
                                    ")",
                                    [astBase.mark])
                            } else {
                                cls.superClass = null(baseClass)
                            }
                        }
                    }
                    else = throw JLError(
                        "Cannot inherit from " + irBase, [astBase.mark])
                }
            }
        })
    }

    private def solveType(self, astType: JLAstType): J3Type {
        when astType.data {
            case noreturn = J3Type.noreturn()
            case void = J3Type.void()
            case int = J3Type.int()
            case double = J3Type.double()
            case klass(name, astArgs) = {
                when getData(astType.mark, name) {
                    case type(type) = {
                        if astArgs {
                            throw JLError("" + type + " is not a template", [astType.mark])
                        } else {
                            type
                        }
                    }
                    case classTemplate(f) = {
                        val irArgs = astArgs.map(e -> solveTemplateArg(e))
                        val data = f.call(astType.mark, irArgs)
                        when data {
                            case type(t) = t
                            else = throw JLError("" + data + " is not a type", [astType.mark])
                        }
                    }
                }
            }
            else = throw JLError("TODO J3ClassSolver.solveType", [astType.mark])
        }
    }

    private def solveTemplateArg(self, astArg: JLAstTemplateArgument): J3Data {
        when astArg.data {
            case int(i) = throw JLError("TODO int template arg", [astArg.mark])
            case type(t) = J3Data.type(solveType(t))
        }
    }

    private def getDataOrNull(self, name: String): Nullable[J3Data] = map.getOrNull(name)

    private def getData(self, mark: JLMark, name: String): J3Data {
        if null(data) = getDataOrNull(name) {
            data
        } else {
            throw JLError("Name " + name + " not found", [mark])
        }
    }
}
