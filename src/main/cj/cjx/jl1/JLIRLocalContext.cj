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
        if texpr.args {
            throw Error("TODO: type expression args")
        }
        val shortName = texpr.name
        if shortName in typeMap {
            val qualifiedName = typeMap[shortName]
            if qualifiedName not in ctx.classMap {
                throw JLError("Class " + qualifiedName + " not found", [texpr.mark])
            }
            JLType.klass(ctx.classMap[qualifiedName])
        } else {
            switch shortName {
                case "Void" = JLType.void()
                case "Bool" = JLType.bool()
                case "Byte" = JLType.byte()
                case "Int" = JLType.int()
                case "Long" = JLType.long()
                case "Float" = JLType.float()
                case "Double" = JLType.double()
                else = throw JLError("Unrecognized type: " + shortName, [texpr.mark])
            }
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
