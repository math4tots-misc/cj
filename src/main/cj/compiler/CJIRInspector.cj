package compiler

import compiler.CJError
import cj.StringBuilder
import compiler.CJIR

class CJIRInspector {
    val sb: StringBuilder = Default()
    var depth = 0
    var showExprs = true

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
            _inspectClassFields(cls)
            _inspectItemMethods(cls)
        })
    }

    def _inspectUnion(self, uni: CJIR.UnionDef) {
        line("union " + uni.name)
        nest(() -> {
            _inspectItemTypeParams(uni)
            _inspectItemTraits(uni)
            _inspectItemMethods(uni)
        })
    }

    def _inspectTrait(self, tr: CJIR.TraitDef) {
        line("trait " + tr.name)
        nest(() -> {
            _inspectItemTypeParams(tr)
            _inspectItemTraits(tr)
            _inspectItemMethods(tr)
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

    def _inspectItemMethods[I: CJIR.ItemDef](self, item: I) {
        if item.methods {
            line("Methods")
            nest(() -> {
                for method in item.methods {
                    val synthetic = if method.synthetic { "(synthetic) " } else { "" }
                    val tparams = if method.typeParameters {
                        "[" + ",".join(method.typeParameters.map(tp -> tp.name)) + "]"
                    } else { "" }
                    val params = "(" + ",".join(method.parameters.map(p -> if p.name == "self" {
                        "self"
                    } else {
                        "" + p.type
                    })) + "):"
                    line(synthetic + method.name + tparams + params + method.returnType)
                    if showExprs {
                        if val body = method.body {
                            nest(() -> _inspectExpr(body))
                        }
                    }
                }
            })
        }
    }

    def _inspectExpr(self, expr: CJIR.Expr) {
        when expr.data {
            case unit = line("()")
            else = throw CJError("TODO inspectExpr " + tag_name!(expr.data), [expr.mark])
        }
    }

    def _inspectClassFields(self, cls: CJIR.ClassDef) {
        if cls.fields {
            line("Fields")
            nest(() -> {
                for field in cls.fields {
                    val static_ = if field.static_ { "static " } else { "" }
                    val mutable = if field.mutable { "var " } else { "val " }
                    line(static_ + mutable + field.name + ": " + field.type)
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
