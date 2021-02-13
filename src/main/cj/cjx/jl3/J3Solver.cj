package cjx.jl3

import cj.StringBuilder
import cjx.jl1.JLError
import cjx.jl3.J3Data
import cjx.jl3.J3ClassSolver
import cjx.jl1.JLAstFile
import cjx.jl1.JLAstClass
import cjx.jl1.JLMark
import cjx.jl3.J3Type
import cjx.jl3.J3Method
import cjx.jl3.J3Class

@derive(new)
class J3Solver {
    val classMap: Map[String, J3Class] = Map()
    val classTemplateMap: Map[String, Fn[JLMark, List[J3Data], J3Data]] = Map()
    val todo1: List[Fn[Unit]] = []
    val todo2: List[Fn[Unit]] = []
    val todo3: List[Fn[Unit]] = []
    val todo4: List[Fn[Unit]] = []
    val todo5: List[Fn[Unit]] = []

    def todo1(self, f: Fn[Unit]) = todo1.add(f)
    def todo2(self, f: Fn[Unit]) = todo2.add(f)
    def todo3(self, f: Fn[Unit]) = todo3.add(f)
    def todo4(self, f: Fn[Unit]) = todo4.add(f)
    def todo5(self, f: Fn[Unit]) = todo5.add(f)

    def solve(self) {
        while todo1 or todo2 or todo3 or todo4 or todo5 {
            if todo1 {
                todo1.pop().call()
            } else if todo2 {
                todo2.pop().call()
            } else if todo3 {
                todo3.pop().call()
            } else if todo4 {
                todo4.pop().call()
            } else {
                todo5.pop().call()
            }
        }
    }

    def registerFile(self, astfile: JLAstFile) {
        val packageName = astfile.packageName
        for astcls in astfile.classes {
            val name = packageName + "." + astcls.shortName
            if astcls.templateParameters {
                classTemplateMap[name] = (mark, templateArgs) -> {
                    val reifiedName = getClassNameFromTemplate(
                        mark,
                        packageName,
                        astcls,
                        templateArgs)
                    if null(cls) = classMap.getOrNull(reifiedName) {
                        J3Data.type(J3Type.klass(cls))
                    } else if astcls.kind.isClassOrInterface() {
                        val id = classMap.size()
                        val kind = if astcls.kind.isInterface() {
                            J3Class.Kind.interface_() } else { J3Class.Kind.class_() }
                        val ircls = J3Class(astcls.mark, id, kind, reifiedName)
                        classMap[reifiedName] = ircls
                        ircls.templateName = name
                        ircls.templateArgs = templateArgs
                        val map = _createMapFromFile(astfile)
                        checkArgc(mark, astcls.templateParameters.size(), templateArgs.size())
                        for i = 0; i < templateArgs.size(); i++ {
                            map[astcls.templateParameters[i].name] = templateArgs[i]
                        }
                        val csolver = J3ClassSolver(self, ircls, map)
                        csolver.initWithAst(astcls)
                        J3Data.type(J3Type.klass(ircls))
                    } else {
                        throw JLError("TODO: template " + astcls.kind, [mark])
                    }
                }
            } else if astcls.kind.isClassOrInterface() {
                val id = classMap.size()
                val kind = if astcls.kind.isInterface() {
                    J3Class.Kind.interface_() } else { J3Class.Kind.class_() }
                val ircls = J3Class(astcls.mark, id, kind, name)
                classMap[name] = ircls
                val map = _createMapFromFile(astfile)
                val csolver = J3ClassSolver(self, ircls, map)
                csolver.initWithAst(astcls)
            } else {
                throw JLError("TODO: " + astcls.kind, [astcls.mark])
            }
        }
    }

    def checkArgc(self, mark: JLMark, expected: Int, actual: Int) {
        if expected != actual {
            throw JLError("Expected " + expected + " args but got " + actual, [mark])
        }
    }

    private def getClassNameFromTemplate(
            self,
            mark: JLMark,
            packageName: String,
            classTemplate: JLAstClass,
            templateArgs: List[J3Data]): String {
        val sb = StringBuilder()
        sb.add(packageName + "." + classTemplate.shortName + "$t$")
        for arg in templateArgs {
            sb.add(when arg {
                case type(type) = when type {
                    case noreturn = "N"
                    case void = "V"
                    case int = "I"
                    case double = "D"
                    case klass(argcls) = "L" + argcls.id
                }
                case classTemplate(f) = throw JLError(
                    "Templates are not allowed as template arguments", [mark])
            })
        }
        sb.toString()
    }

    private def _createMapFromFile(self, file: JLAstFile): Map[String, J3Data] {
        val map: Map[String, J3Data] = Map()
        val packageName = file.packageName
        for import_ in file.imports {
            map[import_.alias] = getData(import_.mark, import_.qualifiedName)
        }
        for astcls in file.classes {
            val fullName = packageName + "." + astcls.shortName
            map[astcls.shortName] = getData(astcls.mark, fullName)
        }
        map
    }

    def getData(self, mark: JLMark, qualifiedName: String): J3Data {
        if null(data) = getDataOrNull(qualifiedName) {
            data
        } else {
            throw JLError("Could not find " + qualifiedName, [mark])
        }
    }

    def getDataOrNull(self, qualifiedName: String): Nullable[J3Data] {
        if null(cls) = classMap.getOrNull(qualifiedName) {
            null(J3Data.type(J3Type.klass(cls)))
        } else if null(classTemplate) = classTemplateMap.getOrNull(qualifiedName) {
            null(J3Data.classTemplate(classTemplate))
        } else {
            null
        }
    }
}
