package cjx.jl2

import cjx.jl2.JLMetaEvaluator
import cjx.jl2.JLMetaScope
import cj.FS
import cjx.jl2.JLMetaParser
import cj.Argv

# jl2 interpreter
class Main {
    def main() {
        val filepath = Argv()[0]
        val string = FS.readFile(filepath)
        val expr = JLMetaParser.parse(filepath, string)
        val scope = JLMetaScope(null)
        val evaluator = JLMetaEvaluator(scope)
        evaluator.eval(expr)
    }
}
