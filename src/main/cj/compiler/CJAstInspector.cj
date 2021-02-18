package compiler

import compiler.CJItemKind
import cj.StringBuilder
import compiler.CJAst

class CJAstInspector {
    val sb: StringBuilder = Default()
    var depth = 0

    private def line(self, line: String) {
        sb.add("  " * depth + line + "\n")
    }

    private def nest(self, f: Fn[Unit]) {
        depth = depth + 1
        f.call()
        depth = depth - 1
    }

    def inspectFile(file: CJAst.File): String {
        val self = Self()
        self._inspectFile(file)
        self.sb.toString()
    }

    def _inspectFile(self, file: CJAst.File) {
        line(file.packageName + "." + file.item.shortName)
        nest(() -> {
            line("package " + file.packageName)
            for imp in file.imports {
                line("import " + imp.fullName + " (" + imp.alias + ")")
            }
            _inspectItem(file.item)
        })
    }

    def _type(t: CJAst.Type): String {
        if t.args {
            t.name + "[" + ", ".join(t.args.map(arg -> _type(arg))) + "]"
        } else {
            t.name
        }
    }

    def _itemkind(itemKind: CJItemKind): String = when itemKind {
        case class_ = "class"
        case union_ = "union"
        case trait_ = "trait"
    }

    def _inspectItem(self, item: CJAst.Item) {
        line(_itemkind(item.kind) + " " + item.shortName)
        nest(() -> {
            for member in item.members {
                _inspectMember(member)
            }
        })
    }

    def _inspectMember(self, member: CJAst.Member) {
        when member {
            case item(item) = _inspectItem(item)
            case field(field) = _inspectField(field)
            case case_(case_) = _inspectCase(case_)
            else = ()
        }
    }

    def _inspectField(self, field: CJAst.Field) {
        val lead = if field.mutable { "var " } else { "val " }
        line(lead + field.name + if null(t) = field.type { ": " + _type(t) } else { "" })
    }

    def _inspectCase(self, case_: CJAst.Case) {
        if case_.types {
            line("case " + case_.name + "(" + ", ".join(case_.types.map(t -> _type(t))) + ")")
        } else {
            line("case " + case_.name)
        }
    }
}
