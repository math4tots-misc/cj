package compiler.main

import compiler.CJC
import compiler.CJS2
import cj.FS
import compiler.solver.CJSolver
import cj.Argv

class Compiler {
    def main() {
        val argv = Argv()
        val solver = CJS2()
        solver.addSourceRoot("main")

        for itemName in argv {
            solver.queueItem(itemName)
        }
        solver.solve()

        val types = solver.program.typeMap.values().sortedBy(t -> t.name)
        val cgen = CJC()

        for type in types {
            IO.println(type.name)
        }
    }
}
