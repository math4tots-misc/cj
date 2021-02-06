package cjx.jl1.main

import cjx.jl1.JLCodegen
import cjx.jl1.JLIRSolver
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

        var mode = Mode.normal()
        for arg in Argv() {
            when mode {
                case normal = {
                    switch arg {
                        case "--out-dir"
                        case "-d" = {
                            mode = Mode.outdir()
                        }
                        else = filenames.add(arg)
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

        val solver = JLIRSolver(ctx)
        solver.solve(astfiles)

        val codegen = JLCodegen(ctx, outdir)
        codegen.emit()
    }

    union Mode {
        case normal
        case outdir
    }
}
