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
            _inspectItemTraits(cls)
        })
    }

    def _inspectUnion(self, uni: CJIR.UnionDef) {
        line("union " + uni.name)
        nest(() -> {
            _inspectItemTypeParams(uni)
            _inspectItemTraits(uni)
        })
    }

    def _inspectTrait(self, tr: CJIR.TraitDef) {
        line("trait " + tr.name)
        nest(() -> {
            _inspectItemTypeParams(tr)
            _inspectItemTraits(tr)
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

    def _inspectItemTraits[I: CJIR.ItemDef](self, item: I) {
        if item.traitDeclarations {
            line("Traits")
            nest(() -> {
                for tdecl in item.traitDeclarations {
                    val hasConditions = tdecl.conditions.size() > 0
                    line("" + tdecl.trait_ + if hasConditions { " (conditional)" } else { "" })
                    nest(() -> {
                        for cond in tdecl.conditions {
                            _inspectTypeCondition(cond)
                        }
                    })
                }
            })
        }
    }

    def _inspectTypeCondition(self, cond: CJIR.TypeCondition) {
        line(cond.variableName)
        nest(() -> {
            for trait_ in cond.traits {
                line("" + trait_)
            }
        })
    }
}
