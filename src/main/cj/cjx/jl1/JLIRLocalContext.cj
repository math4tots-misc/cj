package cjx.jl1

import cjx.jl1.JLMark
import cjx.jl1.JLIRMethod
import cjx.jl1.JLIRClass
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

    ## The current method we're working with.
    ## May be the empty string when none really applies
    val methodName: String

    var _thisClass: Nullable[JLIRClass] = null
    var _thisMethod: Nullable[JLIRMethod] = null

    def __get_thisClass(self): JLIRClass = if null(cls) = _thisClass {
            cls
        } else {
            val cls = ctx.classMap[className]
            _thisClass = null(cls)
            cls
        }

    def __get_thisMethod(self): JLIRMethod = if null(method) = _thisMethod {
            method
        } else if methodName {
            val method = thisClass.methodMap[methodName]
            _thisMethod = null(method)
            method
        } else {
            throw Error("No thisMethod applies here")
        }

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
                    ctx.getClassType(texpr.mark, qualifiedName)
                } else {
                    throw JLError("Unrecognized type name " + shortName, [texpr.mark])
                }
            }
        }
    }

    def getClass(self, mark: JLMark, shortName: String): JLIRClass {
        if null(qualifiedName) = typeMap.getOrNull(shortName) {
            ctx.getClass(mark, qualifiedName)
        } else {
            throw JLError("Unrecognized type name " + shortName, [mark])
        }
    }

    def solveFieldType(self, texpr: JLAstType): JLType {
        val type = solveType(texpr)
        when type {
            case void = throw JLError("void is not allowed here", [texpr.mark])
            else = type
        }
    }

    def solveInterfaceType(self, texpr: JLAstType): JLIRClass {
        val type = solveType(texpr)
        when type {
            case klass(cls) = if cls.isInterface() {
                return cls
            }
            else = ()
        }
        throw JLError("Expected interface type but got " + type, [texpr.mark])
    }
}
