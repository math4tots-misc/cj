package compiler.main

import compiler.CJIRInspector
import compiler.CJParser
import cj.FS
import cj.Argv
import compiler.CJSolver

class Solver {
    def main() {
        val argv = Argv()
        val solver = CJSolver(["src/main/cj"])
        for filename in argv {
            val data = FS.readFile(filename)
            IO.println("Adding " + filename)
            val file = CJParser.parse(filename, data)
            solver.addFile(file)
        }
        solver.solve()
        val pairs = solver.itemMap.pairs().toList()
        pairs.sortBy(pair -> pair.get0())
        for (name, item) in pairs {
            IO.println(CJIRInspector.inspectItem(item))
        }
    }
}
