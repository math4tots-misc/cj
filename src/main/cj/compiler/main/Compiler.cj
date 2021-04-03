package compiler.main

import compiler.CJParser
import compiler.CJIRInspector
import cj.FS
import compiler.solver.CJSolver
import cj.Argv

class Compiler {
    def main() {
        val argv = Argv()
        val solver = CJSolver(["main"])
        for itemName in argv {
            solver.getItemDefOrNull(itemName)
        }
        solver.solve()
        val pairs = solver.itemMap.pairs().toList()
        pairs.sortBy(pair -> pair.f0)
        for (name, item) in pairs {
            IO.println(CJIRInspector.inspectItem(item))
        }
    }
}
