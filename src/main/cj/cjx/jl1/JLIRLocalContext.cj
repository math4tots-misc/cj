package cjx.jl1

import cjx.jl1.JLIRExpressionSolver
import cj.Math
import cjx.jl1.JLAstMethod
import cjx.jl1.JLAstExpr
import cjx.jl1.JLIRExpr
import cjx.jl1.JLAstLocal
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

    val additionalTemplateArgsMap: Map[String, JLIRTemplateArgument] = Map()

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
            case array(inner) = JLType.array(solveFieldType(inner))
            case klass(shortName, astArgs) = {
                val ensurePass2 = methodName.size() > 0
                if shortName == "Self" {
                    JLType.klass(thisClass)
                } else if null(templateArg) = getTemplateArgumentOrNull(shortName) {
                    when templateArg {
                        case type(type) = type
                        else = throw JLError(shortName + " is not a type", [texpr.mark])
                    }
                } else if null(qualifiedName) = typeMap.getOrNull(shortName) {
                    val mark = texpr.mark
                    if astArgs {
                        val irArgs = solveTemplateArgs(mark, astArgs)
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

    def getTemplateArgumentOrNull(self, shortName: String): Nullable[JLIRTemplateArgument] {
        if null(templateArg) = additionalTemplateArgsMap.getOrNull(shortName) {
            null(templateArg)
        } else if null(templateArg) = thisClass.getTemplateArgumentOrNull(shortName) {
            null(templateArg)
        } else {
            null
        }
    }

    def solveClass(self, texpr: JLAstType): JLIRClass {
        val type = solveType(texpr)
        when type {
            case klass(cls) = cls
            else = throw JLError("Class type is expected here", [texpr.mark])
        }
    }

    def getClass(self, mark: JLMark, shortName: String): JLIRClass {
        val type = solveType(JLAstType(mark, JLAstType.Data.klass(shortName, [])))
        when type {
            case klass(cls) = cls
            else = throw JLError("Class type is expected here", [mark])
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
            astArgs: List[JLAstTemplateArgument]): List[JLIRTemplateArgument] {
        astArgs.map(astArg -> solveTemplateArg(astArg))
    }

    def solveTemplateArg(self, arg: JLAstTemplateArgument): JLIRTemplateArgument {
        when arg.data {
            case int(i) = JLIRTemplateArgument.int(i)
            case type(astType) = JLIRTemplateArgument.type(solveType(astType))
        }
    }

    def newMethod(self, astMethod: JLAstMethod, methodName: String): JLIRMethod {
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
                    JLType.klass(thisClass)
                } else {
                    solveFieldType(astLocal.type.get())
                })
            parameters.add(irLocal)
        }
        val irMethod = JLIRMethod(
            astMethod.mark,
            astMethod.comment,
            astMethod.modifiers,
            methodName,
            parameters,
            solveType(astMethod.returnType),
            parameters.clone())
        thisClass.addMethod(irMethod)
        irMethod
    }

    def inferTemplateArgs(
            self,
            solver: JLIRExpressionSolver,
            outerMark: JLMark,
            methodTemplate: JLAstMethod,
            expectedReturnType: Nullable[JLType],
            astArgs: List[JLAstExpr],
            irArgs: List[JLIRExpr]): List[JLIRTemplateArgument] {
        val stack: List[Tuple[JLMark, JLAstTemplateArgument, JLIRTemplateArgument]] = []
        var nextInferArgIndex = 0
        val limit = Math.min(methodTemplate.parameters.size(), astArgs.size())
        val variableNames = methodTemplate.templateParameters.map(tp -> (tp.name, tp)).toMap()
        val target = variableNames.size()
        val map: Map[String, JLIRTemplateArgument] = Map()
        if null(returnType) = expectedReturnType {
            stack.add((
                outerMark,
                JLAstTemplateArgument(outerMark, JLAstTemplateArgument.Data.type(
                    methodTemplate.returnType)),
                JLIRTemplateArgument.type(returnType),
            ))
        }
        while map.size() < target and (stack or nextInferArgIndex < limit) {
            if not stack {
                val i = nextInferArgIndex
                nextInferArgIndex++
                val expr = if i < irArgs.size() {
                    irArgs[i]
                } else {
                    val astArg = astArgs[i]
                    # TODO: lambda expressions
                    val irExpr = solver.solveExpression(astArg, null)
                    irArgs.add(irExpr)
                    irExpr
                }
                val inferMark = expr.mark
                stack.add((
                    inferMark,
                    JLAstTemplateArgument(
                        methodTemplate.parameters[i].mark,
                        JLAstTemplateArgument.Data.type(
                            methodTemplate.parameters[i].type.get())),
                    JLIRTemplateArgument.type(expr.type)))
            }
            val (mark, expected, actual) = stack.pop()
            when expected.data {
                case type(expectedType) = {
                    when expectedType.data {
                        case klass(shortName, astTemplateArgs) = {
                            if shortName in variableNames {
                                if shortName not in map {
                                    # bind: type argument
                                    map[shortName] = actual
                                }
                            } else if null(qualifiedName) = typeMap.getOrNull(shortName) {
                                when actual {
                                    case type(actualType) = when actualType {
                                        case klass(actualClass) = {
                                            if actualClass.unreifiedName == qualifiedName {
                                                # We find matching class templates.
                                                # We can make further inferences based on the
                                                # arguments to these class templates.
                                                val actualArgs = actualClass.templateArgumentsList
                                                val len = Math.min(
                                                    astTemplateArgs.size(),
                                                    actualArgs.size())
                                                for j = 0; j < len; j++ {
                                                    val expectedArg = astTemplateArgs[j]
                                                    val actualArg = actualArgs[j]
                                                    stack.add((mark, expectedArg, actualArg))
                                                }
                                            }
                                        }
                                        else = ()
                                    }
                                    else = ()
                                }
                            }
                        }
                        else = ()
                    }
                }
                else = ()
            }
            # In all other cases, either we can't determine the inference,
            # or expected is a concrete type, so we just skip those
        }
        if map.size() < target {
            throw JLError("Could not infer template arguments", [outerMark])
        }
        methodTemplate.templateParameters.map(tp -> map[tp.name]).toList()
    }
}
