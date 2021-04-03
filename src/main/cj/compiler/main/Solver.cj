package compiler.main

import compiler.CJIRInspector
import compiler.CJParser
import cj.FS
import cj.Argv
import compiler.solver.CJSolver

class Solver {
    def main() {
        val argv = Argv()
        val solver = CJSolver([
            # "src/main/cj2",
            # "src/main/cj",
            "main",
        ])
        for filename in argv {
            val data = FS.readFile(filename)
            IO.println("Adding " + filename)
            val file = CJParser.parse(filename, data)
            solver.addFile(file)
        }
        solver.solve()
        val pairs = solver.itemMap.pairs().toList()
        pairs.sortBy(pair -> pair.f0)
        for (name, item) in pairs {
            IO.println(CJIRInspector.inspectItem(item))
        }
    }
}
