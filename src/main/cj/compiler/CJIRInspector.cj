package compiler

import cj.StringBuilder
import compiler.CJIR

class CJIRInspector {
    val sb: StringBuilder = Default()
    var depth = 0
    var showExprs = false

    private def line(self, line: String) {
        sb.add("  " * depth + line + "\n")
    }

    private def nest(self, f: Fn[Unit]) {
        depth = depth + 1
        f.call()
        depth = depth - 1
    }

    def inspectItem(item: CJIR.Item): String {
        val self = Self()
        self._inspectItem(item)
        self.sb.toString()
    }

    def _inspectItem(self, item: CJIR.Item) {
        when item {
            case class_(cls) = _inspectClass(cls)
            case union_(u) = _inspectUnion(u)
            case trait_(t) = _inspectTrait(t)
        }
    }

    def _inspectClass(self, cls: CJIR.Class) {
        line("class " + cls.name)
    }

    def _inspectUnion(self, uni: CJIR.Union) {
        line("union " + uni.name)
    }

    def _inspectTrait(self, tr: CJIR.Trait) {
        line("trait " + tr.name)
    }
}
