package compiler.codegen

import www.sourcemap.JSBuilder

class CJJSBlob {
    val prep: Fn[JSBuilder, Unit]?
    val body: Fn[JSBuilder, Unit]
    val pure: Bool

    def pure(s: String): Self = Self(null, out -> out.str(s), true)
    def simplestr(s: String): Self = Self(null, out -> out.str(s), false)
    def simple(b: Fn[JSBuilder, Unit]): Self = Self(null, b, false)

    def emitDrop(self, out: JSBuilder) {
        if val p = prep { p.call(out) }
        if not pure {
            body.call(out)
            out.str(";")
        }
    }

    def emitSet(self, out: JSBuilder, target: String) {
        if val p = prep { p.call(out) }
        out.str(target)
        body.call(out)
        out.str(";")
    }
}
