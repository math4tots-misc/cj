package cjx.jl1

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

    val classMap: Map[String, JLIRClass] = Map()
    val classTemplateMap: Map[String, Tuple[JLAstFile, JLAstClass]] = Map()

    ## Registers the classes and class templates in these files without
    ## actually resolving them
    def registerClassesInFiles(self, files: List[JLAstFile]) {
        walkClasses(files, (name, file, astcls, lctx) -> {
            if astcls.templateParameters {
                classTemplateMap[name] = (file, astcls)
            } else {
                newClass(astcls.mark, astcls.modifiers, astcls.isInterface(), name)
            }
        })
    }

    def getClassType(self, mark: JLMark, qualifiedClassName: String): JLType = (
        JLType.klass(getClass(mark, qualifiedClassName)))

    def getClass(self, mark: JLMark, qualifiedClassName: String): JLIRClass {
        if null(cls) = classMap.getOrNull(qualifiedClassName) {
            cls
        } else {
            throw JLError("Class " + qualifiedClassName + " not found", [mark])
        }
    }

    def getReifiedClass(
            self,
            mark: JLMark,
            qualifiedClassName: String,
            templateArgs: List[JLIRTemplateArgument]): JLIRClass {
        val reifiedClassName = getReifiedClassName(mark, qualifiedClassName, templateArgs)
        if reifiedClassName not in classMap {
            if null((astFile, classTemplate)) = classTemplateMap.getOrNull(qualifiedClassName) {
                classMap[reifiedClassName] = initReifiedClass(
                    mark, reifiedClassName, astFile, classTemplate)
            } else {
                throw JLError("Class template " + qualifiedClassName + " not found", [mark])
            }
        }
        classMap[reifiedClassName]
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

    def qualifyClassName(file: JLAstFile, cls: JLAstClass): String = (
        file.packageName + "." + cls.shortName)

    def qualifyInnerClassName(outerClassName: String, cls: JLAstClass): String =(
        outerClassName + "$" + cls.shortName)

    def buildTypeMap(astFile: JLAstFile): Map[String, String] {
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
            f: Fn[String, JLAstFile, JLAstClass, JLIRLocalContext, Unit]) {
        for file in files {
            val typeMap = JLContext.buildTypeMap(file)
            for cls in file.classes {
                val name = JLContext.qualifyClassName(file, cls)
                val lctx = JLIRLocalContext(self, typeMap, name, "")
                f.call(name, file, cls, lctx)
                for member in cls.members {
                    when member {
                        case klass(innercls) = {
                            val innerName = JLContext.qualifyInnerClassName(name, innercls)
                            val innerLctx = JLIRLocalContext(self, typeMap, innerName, "")
                            f.call(innerName, file, innercls, innerLctx)
                        }
                        else = ()
                    }
                }
            }
        }
    }

    def newClass(
            self,
            mark: JLMark,
            modifiers: List[String],
            isInterface: Bool,
            qualifiedName: String): JLIRClass {
        val id = classMap.size()
        val ircls = JLIRClass(
            mark,
            id,
            modifiers,
            isInterface,
            qualifiedName)
        classMap[qualifiedName] = ircls
        ircls
    }

    private def initReifiedClass(
            self,
            mark: JLMark,
            reifiedClassName: String,
            astFile: JLAstFile,
            classTemplate: JLAstClass): JLIRClass {
        val ircls = newClass(
            classTemplate.mark,
            classTemplate.modifiers,
            classTemplate.isInterface(),
            reifiedClassName)
        val typeMap = buildTypeMap(astFile)
        val lctx = JLIRLocalContext(self, typeMap, reifiedClassName, "")
        throw Error("TDOO")
    }
}
