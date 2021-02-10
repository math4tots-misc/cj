package cjx.jl1

import cjx.jl1.JLAstTemplateArgument
import cjx.jl1.JLAstTemplateParameter
import cjx.jl1.JLIRTemplateArgument
import cjx.jl1.JLIRLocal
import cjx.jl1.JLMark
import cjx.jl1.JLIRMethod
import cjx.jl1.JLIRClass
import cjx.jl1.JLError
import cj.Error
import cjx.jl1.JLType
import cjx.jl1.JLAstType
import cjx.jl1.JLContext

class JLIRLocalContext {
    ## Global context
    val ctx: JLContext

    ## Maps shortName to qualifiedNames (for imports and local and inner classes)
    val typeMap: Map[String, String]

    ## Name of the current class
    val className: String

    ## The current method we're working with.
    ## May be the empty string when none really applies
    val methodName: String

    var _thisClass: Nullable[JLIRClass] = null
    var _thisMethod: Nullable[JLIRMethod] = null

    val localStack: List[Map[String, JLIRLocal]] = [Map()]

    def new(ctx: JLContext,
            typeMap: Map[String, String],
            className: String,
            methodName: String): Self {
        val self = __malloc(ctx, typeMap, className, methodName)
        if methodName {
            for parameter in thisMethod.parameters {
                localStack.last()[parameter.name] = parameter
            }
        }
        self
    }

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
            case klass(shortName, astArgs) = {
                val ensurePass2 = methodName.size() > 0
                if null(templateArg) = thisClass.templateArguments.getOrNull(shortName) {
                    when templateArg {
                        case type(type) = type
                        else = throw JLError(shortName + " is not a type", [texpr.mark])
                    }
                } else if null(qualifiedName) = typeMap.getOrNull(shortName) {
                    val mark = texpr.mark
                    if astArgs {
                        val classTemplate = ctx.getClassTemplate(mark, qualifiedName)
                        val irArgs = solveTemplateArgs(
                            mark, classTemplate.templateParameters, astArgs)
                        ctx.getReifiedClassType(mark, qualifiedName, irArgs, ensurePass2)
                    } else {
                        ctx.getClassType(mark, qualifiedName, ensurePass2)
                    }
                } else {
                    throw JLError("Unrecognized type name " + shortName, [texpr.mark])
                }
            }
        }
    }

    def solveClass(self, texpr: JLAstType): JLIRClass {
        val type = solveType(texpr)
        when type {
            case klass(cls) = cls
            else = throw JLError("Calss type is expected here", [texpr.mark])
        }
    }

    def getClass(self, mark: JLMark, shortName: String): JLIRClass {
        if null(qualifiedName) = typeMap.getOrNull(shortName) {
            ctx.getClass(mark, qualifiedName, methodName.size() > 0)
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

    def pushScope(self) {
        localStack.add(Map())
    }

    def popScope(self) {
        localStack.pop()
    }

    def getLocalOrNull(self, name: String): Nullable[JLIRLocal] {
        for i = localStack.size() - 1; i >= 0; i-- {
            if null(entry) = localStack[i].getOrNull(name) {
                return null(entry)
            }
        }
        null
    }

    def newLocal(
            self,
            mark: JLMark,
            modifiers: List[String],
            name: String,
            type: JLType): JLIRLocal {
        val local = thisMethod.newLocal(mark, modifiers, name, type)
        localStack.last()[name] = local
        local
    }

    def solveTemplateArgs(
            self,
            mark: JLMark,
            params: List[JLAstTemplateParameter],
            astArgs: List[JLAstTemplateArgument]): List[JLIRTemplateArgument] {
        if params.size() != astArgs.size() {
            throw JLError("Expected " + params.size() + " args but got " + astArgs.size(), [mark])
        }
        val args: List[JLIRTemplateArgument] = []
        for i = 0; i < params.size(); i++ {
            val param = params[i]
            val astArg = astArgs[i]
            args.add(when param.kind {
                case int = when astArg.data {
                    case int(i) = JLIRTemplateArgument.int(i)
                    else = throw JLError("Expected int template argument", [astArg.mark])
                }
                case type = when astArg.data {
                    case type(astType) = JLIRTemplateArgument.type(solveType(astType))
                    else = throw JLError("Expected type template argument", [astArg.mark])
                }
            })
        }
        args
    }
}
