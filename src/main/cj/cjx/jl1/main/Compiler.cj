package cjx.jl1.main

import cj.StringBuilder
import cjx.jl1.JLAstExpr
import cjx.jl1.JLAstType
import cjx.jl1.JLAstClass
import cjx.jl1.JLCodegen
import cjx.jl1.JLParser
import cj.FS
import cjx.jl1.JLAstFile
import cj.Error
import cjx.jl1.JLError
import cj.Argv
import cjx.jl1.JLContext

class Compiler {
    def main() {
        val filenames: List[String] = []
        var outdir = ""
        var emitTest = false

        var mode = Mode.normal()
        for arg in Argv() {
            when mode {
                case normal = {
                    switch arg {
                        case "--out-dir"
                        case "-d" = {
                            mode = Mode.outdir()
                        }
                        case "-t" = {
                            emitTest = true
                        }
                        else = {
                            if arg.startsWith("-") {
                                throw Error("Unrecognized flag " + arg)
                            } else {
                                filenames.add(arg)
                            }
                        }
                    }
                }
                case outdir = {
                    outdir = arg
                    mode = Mode.normal()
                }
            }
        }

        if not outdir {
            throw Error("outdir must be specified (i.e. --out-dir)")
        }

        val astfiles: List[JLAstFile] = []
        for filename in filenames {
            val string = FS.readFile(filename)
            val astfile = JLParser.parse(filename, string)
            astfiles.add(astfile)
        }

        val ctx = JLContext()
        ctx.registerClassesInFiles(astfiles)
        ctx.resolveAllRegisteredClasses()

        if emitTest {
            emitTest(ctx)
        }

        val codegen = JLCodegen(ctx, outdir)
        codegen.emit()
    }

    union Mode {
        case normal
        case outdir
    }

    def getTestMap(ctx: JLContext): Map[String, List[String]] {
        val map: Map[String, List[String]] = Map([])
        for cls in ctx.classMap.values() {
            for method in cls.methods {
                if "test" in method.modifiers {
                    if cls.name not in map {
                        map[cls.name] = []
                    }
                    map[cls.name].add(method.name)
                }
            }
            if cls.name in map {
                map[cls.name].sort()
            }
        }
        map
    }

    def emitTest(ctx: JLContext) {

        val testMap = getTestMap(ctx)
        val classNames = testMap.keys().sorted()
        val classToShortNameMap: Map[String, String] = Map([])
        for i = 0; i < classNames.size(); i++ {
            classToShortNameMap[classNames[i]] = "C" + i
        }
        val testCount = testMap.values().map(list -> list.size()).fold(0, (a, b) -> a + b)

        val sb = StringBuilder()
        sb.add("package jl1.test\n")
        sb.add("import jl1.IO\n")
        for className in classNames {
            sb.add("import " + className + " as " + classToShortNameMap[className] + "\n")
        }
        sb.add("class RunAllTests {\n")
        sb.add("  def main(args: String[]) {\n")
        sb.add("    IO.println(\"== jl1 TESTS ==\")\n")
        for className in classNames {
            val shortName = classToShortNameMap[className]
            sb.add("    IO.println(\"  in " + className + "\")\n")
            for methodName in testMap[className] {
                sb.add("    IO.println(\"    " + methodName + "\")\n")
                sb.add("    " + shortName + "." + methodName + "()\n")
            }
        }
        sb.add("    IO.println(\"" + testCount + " tests in " + testMap.size() + " classes pass\")\n")
        sb.add("  }\n")
        sb.add("}\n")
        val code = sb.toString()
        val file = JLParser.parse("<test>", code)
        ctx.registerClassesInFiles([file])
        ctx.resolveAllRegisteredClasses()
    }
}
