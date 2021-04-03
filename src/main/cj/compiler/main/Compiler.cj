package compiler.main

import compiler.codegen.CJCodegen
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
        val items = solver.itemMap.values().sortedBy(i -> i.name)
        val cgen = CJCodegen()
        val jsb = cgen.emit(items)
        jsb.inlineSourceMap = true
        IO.println(jsb.getSource())
    }
}
