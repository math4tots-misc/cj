package cjx.jl1.main

import cj.Error
import cjx.jl1.JLError
import cj.Argv
import cjx.jl1.JLContext

class Compiler {
    def main() {

        val files: List[String] = []
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
                        else = files.add(arg)
                    }
                }
                case outdir = {
                    outdir = arg
                    mode = Mode.normal()
                }
            }
        }

        if not outdir {
            throw Error("outdir must be specified (i.e. --out-dir")
        }

        val ctx = JLContext()
    }

    union Mode {
        case normal
        case outdir
    }
}
