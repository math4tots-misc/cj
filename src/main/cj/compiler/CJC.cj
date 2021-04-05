package compiler

import www.sourcemap.JSBuilder
import compiler.CJLR

## CJ code generator
class CJC {
    val out: JSBuilder = JSBuilder()

    def emit(self, program: CJLR.Program) {
        val types = program.typeMap.values().sortedBy(t -> t.name)
        for type in types {
            IO.println(type.name)
        }
    }
}
