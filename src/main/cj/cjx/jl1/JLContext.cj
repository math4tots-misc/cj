package cjx.jl1

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
        for astInterface in astcls.interfaces {
            val irInterface = lctx.solveInterfaceType(astInterface)
            ircls.interfaces.add(irInterface)
        }
    }

    ## pass2
    ## Materializes all field and method declarations of the given class.
    ## Associated expressions however are not touched.
    private def runPass2(self, ircls: JLIRClass) {
        val lctx = JLIRLocalContext(self, typeMapMap[ircls.id], ircls.name, "")
        val astcls = astClassMap[ircls.id]
        val thisType = JLType.klass(ircls)

        addSynthesizedInit(astcls)

        for astMember in astcls.members {
            when astMember {
                case klass(innercls) = ()
                case field(astField) = {
                    val fieldtype = if null(ftype) = astField.type {
                        ftype
                    } else if null(init) = astField.init {
                        if null(ftype) = simpleInferExpressionType(init) {
                            ftype
                        } else {
                            throw JLError("Could not infer field type", [astField.mark])
                        }
                    } else {
                        throw JLError("Field type is not specified", [astField.mark])
                    }
                    val irField = JLIRField(
                        astField.mark,
                        astField.comment,
                        astField.modifiers,
                        astField.name,
                        lctx.solveFieldType(fieldtype))
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
    }

    private def simpleInferExpressionType(self, expr: JLAstExpr): Nullable[JLAstType] {
        val nullableData = when expr.data {
            case int(i) = null(JLAstType.Data.int())
            case string(s) = null(JLAstType.Data.klass("java.lang.String", []))
            else = null
        }
        if null(data) = nullableData {
            null(JLAstType(expr.mark, data))
        } else {
            null
        }
    }

    private def addSynthesizedInit(self, astcls: JLAstClass) {
        if astcls.isInterface() {
            # Interfaces don't have <init> methods
            return ()
        }

        val mark = astcls.mark
        val parameters = [JLAstLocal(mark, [], "this", null, null)]
        val bodyexprs = [
            # start by calling the super constructor
            JLAstExpr(mark, JLAstExpr.Data.calljava(
                "special",
                JLAstType(mark, JLAstType.Data.void()),
                "java/lang/Object", "<init>", "()V", [JLAstExpr(mark, JLAstExpr.Data.this())],
            )),
        ]
        for field in astcls.fields.filter(f -> not f.isStatic()) {
            bodyexprs.add(JLAstExpr(mark, JLAstExpr.Data.initfield(
                field.name,
                if field.init.isPresent() {
                    field.init.get()
                } else {
                    if field.type.isEmpty() {
                        throw JLError(
                            "A field without an initializer must provide a type", [field.mark])
                    }
                    val fieldtype = field.type.get()
                    val parameterName = "p$" + field.name
                    parameters.add(JLAstLocal(mark, [], parameterName, null(fieldtype), null))
                    JLAstExpr(mark, JLAstExpr.Data.getvar(parameterName))
                }
            )))
        }
        val body = JLAstExpr(mark, JLAstExpr.Data.block(bodyexprs))
        astcls.members.add(JLAstClass.Member.method(JLAstMethod(
            mark,
            null,
            ["private"],
            "<init>",
            parameters,
            JLAstType(mark, JLAstType.Data.void()),
            null(body))))
    }

    ## pass3
    ## Resolves all expressions attached to fields and methods.
    private def runPass3(self, ircls: JLIRClass) {
        val lctx = JLIRLocalContext(self, typeMapMap[ircls.id], ircls.name, "")
        val astcls = astClassMap[ircls.id]
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
    }

    def getClassTemplate(
            self,
            mark: JLMark,
            qualifiedClassName: String): JLAstClass {
        if null((typeMap, classTemplate)) = classTemplateMap.getOrNull(qualifiedClassName) {
            classTemplate
        } else {
            throw JLError("Class template " + qualifiedClassName + " not found", [mark])
        }
    }

    def getClassType(self, mark: JLMark, qualifiedClassName: String, ensurePass2: Bool): JLType = (
        JLType.klass(getClass(mark, qualifiedClassName, ensurePass2)))

    def getClass(self, mark: JLMark, qualifiedClassName: String, ensurePass2: Bool): JLIRClass {
        if null(cls) = classMap.getOrNull(qualifiedClassName) {
            if ensurePass2 {
                resolvePendingClassesThroughPass2()
            }
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
                initReifiedClass(mark, reifiedClassName, typeMap, classTemplate, templateArgs)
            } else {
                throw JLError("Class template " + qualifiedClassName + " not found", [mark])
            }
        }
        if ensurePass2 {
            resolvePendingClassesThroughPass2()
        }
        classMap[reifiedClassName]
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
                    case void() = sb.add("V")
                    case int() = sb.add("I")
                    case long() = sb.add("J")
                    case float() = sb.add("F")
                    case double() = sb.add("D")
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
            typeMap: Map[String, String],
            classTemplate: JLAstClass,
            templateArgs: List[JLIRTemplateArgument]) {
        val ircls = newClass(typeMap, classTemplate, reifiedClassName)
        Assert.equal(classTemplate.templateParameters.size(), templateArgs.size())
        for i = 0; i < templateArgs.size(); i++ {
            val name = classTemplate.templateParameters[i].name
            ircls.templateArguments[name] = templateArgs[i]
        }
    }
}
