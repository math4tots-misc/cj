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

    def inspectItem(item: CJIR.ItemDef): String {
        val self = Self()
        self._inspectItem(item)
        self.sb.toString()
    }

    def _inspectItem(self, item: CJIR.ItemDef) {
        when item {
            case class_(cls) = _inspectClass(cls)
            case union_(u) = _inspectUnion(u)
            case trait_(t) = _inspectTrait(t)
        }
    }

    def _inspectClass(self, cls: CJIR.ClassDef) {
        line("class " + cls.name)
        nest(() -> {
            _inspectItemTypeParams(cls)
        })
    }

    def _inspectUnion(self, uni: CJIR.UnionDef) {
        line("union " + uni.name)
        nest(() -> {
            _inspectItemTypeParams(uni)
        })
    }

    def _inspectTrait(self, tr: CJIR.TraitDef) {
        line("trait " + tr.name)
        nest(() -> {
            _inspectItemTypeParams(tr)
        })
    }

    def _inspectItemTypeParams[I: CJIR.ItemDef](self, item: I) {
        if item.typeParameters {
            line("Type Parameters")
            nest(() -> {
                for tp in item.typeParameters {
                    line(tp.name)
                }
            })
        }
    }
}
