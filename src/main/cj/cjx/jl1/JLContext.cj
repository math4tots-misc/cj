package cjx.jl1

import cjx.jl1.JLPass3
import cjx.jl1.JLToken
import cjx.jl1.JLIRMethodRef
import cjx.jl1.JLPass2
import cjx.jl1.JLAstLocal
import cjx.jl1.JLAstType
import cjx.jl1.JLAstMethod
import cjx.jl1.JLAstExpr
import cjx.jl1.JLAstTemplateParameter
import cjx.jl1.JLIRExpressionSolver
import cjx.jl1.JLIRMethod
import cjx.jl1.JLIRLocal
import cjx.jl1.JLIRField
import cj.Error
import cjx.jl1.JLAstFile
import cjx.jl1.JLIRLocalContext
import cj.StringBuilder
import cjx.jl1.JLIRTemplateArgument
import cjx.jl1.JLAstClass
import cjx.jl1.JLError
import cjx.jl1.JLMark
import cjx.jl1.JLType
import cjx.jl1.JLIRClass

@derive(new)
class JLContext {
    static val builtinTypeMap: Map[String, String] = Map(
        "Object": "java.lang.Object",
        "String": "java.lang.String",
    )

    ## Maps class id to AstClasses
    val astClassMap: List[JLAstClass] = []

    ## Maps class id to typemaps (mapping from short names to qualified
    ## names)
    val typeMapMap: List[Map[String, String]] = []

    val classMap: Map[String, JLIRClass] = Map()
    val classTemplateMap: Map[String, Tuple[Map[String, String], JLAstClass]] = Map()

    private val pass1Todo: List[JLIRClass] = []
    private val pass1Seen: Set[Int] = Set()
    private val pass2Todo: List[JLIRClass] = []
    private val pass2Seen: Set[Int] = Set()
    private val pass3Todo: List[JLIRClass] = []
    private val pass3Seen: Set[Int] = Set()

    ## Registers the classes and class templates in these files without
    ## actually resolving them
    def registerClassesInFiles(self, files: List[JLAstFile]) {
        walkClasses(files, (name, file, astcls, typeMap) -> {
            if astcls.templateParameters {
                classTemplateMap[name] = (typeMap, astcls)
            } else {
                newClass(typeMap, astcls, name)
            }
        })
    }

    def resolveAllRegisteredClasses(self) {
        while pass1Todo or pass2Todo or pass3Todo {
            if pass1Todo {
                val ircls = pass1Todo.pop()
                runPass1(ircls)
                registerForPass2(ircls)
            } else if pass2Todo {
                val ircls = pass2Todo.pop()
                runPass2(ircls)
                registerForPass3(ircls)
            } else if pass3Todo {
                val ircls = pass3Todo.pop()
                runPass3(ircls)
            } else {
                throw Error("FUBAR: resolveAllRegisteredClasses")
            }
        }
    }

    def resolvePendingClassesThroughPass2(self) {
        while pass1Todo or pass2Todo {
            if pass1Todo {
                val ircls = pass1Todo.pop()
                runPass1(ircls)
                registerForPass2(ircls)
            } else if pass2Todo {
                val ircls = pass2Todo.pop()
                runPass2(ircls)
                registerForPass3(ircls)
            } else {
                throw Error("FUBAR: resolvePendingClassesThroughPass2")
            }
        }
    }

    private def registerForPass1(self, ircls: JLIRClass) {
        if ircls.id not in pass1Seen {
            pass1Todo.add(ircls)
            pass1Seen.add(ircls.id)
        }
    }

    private def registerForPass2(self, ircls: JLIRClass) {
        if ircls.id not in pass2Seen {
            pass2Todo.add(ircls)
            pass2Seen.add(ircls.id)
        }
    }

    private def registerForPass3(self, ircls: JLIRClass) {
        if ircls.id not in pass3Seen {
            pass3Todo.add(ircls)
            pass3Seen.add(ircls.id)
        }
    }

    ## pass1
    ## Materializes all declared interfaces of the given class.
    private def runPass1(self, ircls: JLIRClass) {
        val lctx = JLIRLocalContext(self, typeMapMap[ircls.id], ircls.name, "")
        val astcls = astClassMap[ircls.id]
        if ircls.name != "java.lang.Object" {
            ircls.superClass = (
                if null(scls) = astcls.superClass {
                    lctx.solveClass(scls)
                } else {
                    getClass(Default(), "java.lang.Object", false)
                })
        }
        for astInterface in astcls.interfaces {
            val irInterface = lctx.solveInterfaceType(astInterface)
            ircls.interfaces.add(irInterface)
        }
    }

    ## pass2
    ## Materializes all field and method declarations of the given class.
    ## Associated expressions however are not touched.
    private def runPass2(self, ircls: JLIRClass) {
        JLPass2(self).run(ircls)
    }

    ## pass3
    ## Resolves all expressions attached to fields and methods.
    private def runPass3(self, ircls: JLIRClass) {
        JLPass3(self).run(ircls)
    }

    def getClassTemplateOrNull(
            self,
            qualifiedClassName: String): Nullable[JLAstClass] {
        if null((typeMap, classTemplate)) = classTemplateMap.getOrNull(qualifiedClassName) {
            null(classTemplate)
        } else {
            null
        }
    }

    def getClassTemplate(
            self,
            mark: JLMark,
            qualifiedClassName: String): JLAstClass {
        if null(classTemplate) = getClassTemplateOrNull(qualifiedClassName) {
            classTemplate
        } else {
            throw JLError("Class template " + qualifiedClassName + " not found", [mark])
        }
    }

    def getClassType(self, mark: JLMark, qualifiedClassName: String, ensurePass2: Bool): JLType = (
        JLType.klass(getClass(mark, qualifiedClassName, ensurePass2)))

    def getClassOrNull(self, qualifiedClassName: String, ensurePass2: Bool): Nullable[JLIRClass] {
        if null(cls) = classMap.getOrNull(qualifiedClassName) {
            if ensurePass2 {
                resolvePendingClassesThroughPass2()
            }
            null(cls)
        } else {
            null
        }
    }

    def getClass(self, mark: JLMark, qualifiedClassName: String, ensurePass2: Bool): JLIRClass {
        if null(cls) = getClassOrNull(qualifiedClassName, ensurePass2) {
            cls
        } else {
            throw JLError("Class " + qualifiedClassName + " not found", [mark])
        }
    }

    def getReifiedClass(
            self,
            mark: JLMark,
            qualifiedClassName: String,
            templateArgs: List[JLIRTemplateArgument],
            ensurePass2: Bool): JLIRClass {
        val reifiedClassName = getReifiedClassName(mark, qualifiedClassName, templateArgs)
        if reifiedClassName not in classMap {
            if null((typeMap, classTemplate)) = classTemplateMap.getOrNull(qualifiedClassName) {
                checkTemplateArgs(mark, classTemplate.templateParameters, templateArgs)
                initReifiedClass(
                    mark,
                    reifiedClassName,
                    qualifiedClassName,
                    typeMap,
                    classTemplate,
                    templateArgs)
            } else {
                throw JLError("Class template " + qualifiedClassName + " not found", [mark])
            }
        }
        if ensurePass2 {
            resolvePendingClassesThroughPass2()
        }
        classMap[reifiedClassName]
    }

    def getListClass(self, mark: JLMark, itemType: JLType, ensurePass2: Bool): JLIRClass {
        getReifiedClass(
            mark,
            "jl1.List",
            [JLIRTemplateArgument.type(itemType)],
            ensurePass2)
    }

    def getListType(self, mark: JLMark, itemType: JLType, ensurePass2: Bool): JLType {
        JLType.klass(getListClass(mark, itemType, ensurePass2))
    }

    def getReifiedClassType(
            self,
            mark: JLMark,
            qualifiedClassName: String,
            templateArgs: List[JLIRTemplateArgument],
            ensurePass2: Bool): JLType {
        JLType.klass(getReifiedClass(mark, qualifiedClassName, templateArgs, ensurePass2))
    }

    private def getReifiedClassName(
            mark: JLMark,
            qualifiedClassName: String,
            templateArgs: List[JLIRTemplateArgument]): String {
        val sb = StringBuilder()
        sb.add(qualifiedClassName)
        sb.add("$T$")
        for arg in templateArgs {
            when arg {
                case int(i) = {
                    if i < 0 {
                        sb.add("im" + -i)
                    } else {
                        sb.add("i" + i)
                    }
                }
                case type(type) = when type {
                    case noreturn() = sb.add("N")
                    case void() = sb.add("V")
                    case int() = sb.add("I")
                    case long() = sb.add("J")
                    case float() = sb.add("F")
                    case double() = sb.add("D")
                    case klass(cls) = sb.add("L" + cls.id)
                    else = throw JLError(
                        "" + type + " is not supported as a template argument", [mark])
                }
            }
        }
        sb.toString()
    }

    private def qualifyClassName(file: JLAstFile, cls: JLAstClass): String = (
        file.packageName + "." + cls.shortName)

    private def qualifyInnerClassName(outerClassName: String, cls: JLAstClass): String =(
        outerClassName + "$" + cls.shortName)

    private def buildTypeMap(astFile: JLAstFile): Map[String, String] {
        val typeMap = builtinTypeMap.clone()
        for imp in astFile.imports {
            typeMap[imp.alias] = imp.qualifiedName
        }
        for cls in astFile.classes {
            val name = qualifyClassName(astFile, cls)
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
        typeMap
    }

    private def walkClasses(
            self,
            files: List[JLAstFile],
            f: Fn[String, JLAstFile, JLAstClass, Map[String, String], Unit]) {
        for file in files {
            val typeMap = buildTypeMap(file)
            for cls in file.classes {
                val name = qualifyClassName(file, cls)
                f.call(name, file, cls, typeMap)
                for member in cls.members {
                    when member {
                        case klass(innercls) = {
                            val innerName = qualifyInnerClassName(name, innercls)
                            f.call(innerName, file, innercls, typeMap)
                        }
                        else = ()
                    }
                }
            }
        }
    }

    def newClass(
            self,
            typeMap: Map[String, String],
            astClass: JLAstClass,
            qualifiedName: String): JLIRClass {
        val id = classMap.size()
        Assert.equal(id, astClassMap.size())
        Assert.equal(id, typeMapMap.size())
        astClassMap.add(astClass)
        typeMapMap.add(typeMap)
        val ircls = JLIRClass(
            astClass.mark,
            id,
            astClass.modifiers,
            astClass.isInterface(),
            qualifiedName)
        classMap[qualifiedName] = ircls
        registerForPass1(ircls)
        ircls
    }

    private def initReifiedClass(
            self,
            mark: JLMark,
            reifiedClassName: String,
            qualifiedClassName: String,
            typeMap: Map[String, String],
            classTemplate: JLAstClass,
            templateArgs: List[JLIRTemplateArgument]) {
        val ircls = newClass(typeMap, classTemplate, reifiedClassName)
        ircls.unreifiedName = qualifiedClassName
        Assert.equal(classTemplate.templateParameters.size(), templateArgs.size())
        for i = 0; i < templateArgs.size(); i++ {
            val name = classTemplate.templateParameters[i].name
            ircls.addTemplateArgument(name, templateArgs[i])
        }
    }

    def getReifiedMethod(
            self,
            mark: JLMark,
            ircls: JLIRClass,
            methodTemplate: JLAstMethod,
            targs: List[JLIRTemplateArgument]): JLIRMethodRef {
        val methodName = getReifiedMethodName(mark, methodTemplate.name, targs)
        if null(methodref) = ircls.getMethodRefOrNull(methodName) {
            methodref
        } else {
            JLIRMethodRef(ircls, reifyMethod(mark, ircls, methodTemplate, targs))
        }
    }

    private def reifyMethod(
            self,
            mark: JLMark,
            ircls: JLIRClass,
            methodTemplate: JLAstMethod,
            targs: List[JLIRTemplateArgument]): JLIRMethod {
        val tparams = methodTemplate.templateParameters
        checkTemplateArgs(mark, tparams, targs)
        val lctx0 = JLIRLocalContext(self, typeMapMap[ircls.id], ircls.name, "")
        for i = 0; i < tparams.size(); i++ {
            lctx0.additionalTemplateArgsMap[tparams[i].name] = targs[i]
        }
        val methodName = getReifiedMethodName(mark, methodTemplate.name, targs)
        val irMethod = lctx0.newMethod(methodTemplate, methodName)

        # reifyMethod should only be called as a response to a pass3 event.
        # So it should be safe to materialize the methods as well when a
        # template method is instantiated.
        if methodTemplate.body.isPresent() {
            val astBody = methodTemplate.body.get()
            val mlctx = JLIRLocalContext(
                lctx0.ctx,
                lctx0.typeMap,
                lctx0.className,
                irMethod.name)
            mlctx.additionalTemplateArgsMap.addAll(lctx0.additionalTemplateArgsMap.pairs())
            val esolver = JLIRExpressionSolver(mlctx)
            val irBody = esolver.solveExpression(
                astBody, null(irMethod.returnType))
            irMethod.body = null(irBody)
        }

        irMethod
    }

    private def getReifiedMethodName(
            mark: JLMark,
            methodTemplateName: String,
            templateArgs: List[JLIRTemplateArgument]): String {
        val sb = StringBuilder()
        sb.add(methodTemplateName)
        sb.add("$T$")
        for arg in templateArgs {
            when arg {
                case int(i) = {
                    if i < 0 {
                        sb.add("im" + -i)
                    } else {
                        sb.add("i" + i)
                    }
                }
                case type(type) = when type {
                    case noreturn() = sb.add("N")
                    case void() = sb.add("V")
                    case int() = sb.add("I")
                    case long() = sb.add("J")
                    case float() = sb.add("F")
                    case double() = sb.add("D")
                    case klass(cls) = sb.add("L" + cls.id)
                    else = throw JLError(
                        "" + type + " is not supported as a template argument", [mark])
                }
            }
        }
        sb.toString()
    }

    private def checkTemplateArgs(
            self,
            mark: JLMark,
            params: List[JLAstTemplateParameter],
            args: List[JLIRTemplateArgument],
            ) {
        if params.size() != args.size() {
            throw JLError(
                "Expected " + params.size() + " template args but got " + args.size(),
                [mark])
        }
        for i = 0; i < args.size(); i++ {
            val param = params[i]
            val arg = args[i]
            when param.kind {
                case int = when arg {
                    case int(i) = ()
                    else = throw JLError("Expected int template argument", [mark])
                }
                case type = when arg {
                    case type(t) = ()
                    else = throw JLError("Expected type template argument", [mark])
                }
            }
        }
    }
}
