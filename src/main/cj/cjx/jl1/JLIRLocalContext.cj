package cjx.jl1

import cjx.jl1.JLError
import cj.Error
import cjx.jl1.JLType
import cjx.jl1.JLAstType
import cjx.jl1.JLContext

@derive(new)
class JLIRLocalContext {
    ## Global context
    val ctx: JLContext

    ## Name of the current class
    val className: String

    ## Maps shortName to qualifiedNames (for imports and local and inner classes)
    val typeMap: Map[String, String]

    def solveType(self, texpr: JLAstType): JLType {
        when texpr.data {
            case void = JLType.void()
            case bool = JLType.bool()
            case byte = JLType.byte()
            case char = JLType.char()
            case short = JLType.short()
            case int = JLType.int()
            case long = JLType.long()
            case float = JLType.float()
            case double = JLType.double()
            case array(inner) = JLType.array(solveType(inner))
            case klass(shortName, args) = {
                if args {
                    throw JLError("TODO: type expression args", [texpr.mark])
                }
                if null(qualifiedName) = typeMap.getOrNull(shortName) {
                    if null(cls) = ctx.classMap.getOrNull(qualifiedName) {
                        JLType.klass(cls)
                    } else {
                        throw JLError("Class " + qualifiedName + " not found", [texpr.mark])
                    }
                } else {
                    throw JLError("Unrecognized type name " + shortName, [texpr.mark])
                }
            }
        }
    }

    def solveFieldType(self, texpr: JLAstType): JLType {
        val type = solveType(texpr)
        when type {
            case void = throw JLError("void is not allowed here", [texpr.mark])
            else = type
        }
    }

    def solveInterfaceType(self, texpr: JLAstType): JLType {
        val type = solveType(texpr)
        if type.isInterface() {
            type
        } else {
            throw JLError("Expected interface type but got " + type, [texpr.mark])
        }
    }
}
