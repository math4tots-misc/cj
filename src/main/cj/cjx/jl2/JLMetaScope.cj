package cjx.jl2

import cj.Error
import cj.StringBuilder
import cjx.jl2.JLMetaEvaluator
import cjx.jl1.JLError
import cjx.jl2.JLMetaVal

class JLMetaScope {

    static val builtinFunctions: Map[String, Fn[JLMetaEvaluator, List[JLMetaVal], JLMetaVal]] = (
        Map(
            "print": (ev, args) -> {
                ev.checkArgc(1, args.size())
                IO.println(args[0])
                Default()
            },
            "cat": (ev, args) -> {
                val sb = StringBuilder()
                for arg in args {
                    sb.add(arg.toString())
                }
                JLMetaVal.string(sb.toString())
            },
            "add": (ev, args) -> {
                var total = 0.0
                for arg in args {
                    when arg {
                        case number(x) = { total += x }
                        else = throw ev.err("type error")
                    }
                }
                JLMetaVal.number(total)
            },
            "eq": (ev, args) -> {
                ev.checkArgc(2, args.size())
                JLMetaVal.bool(args[0] == args[1])
            },
            "lt": (ev, args) -> {
                ev.checkArgc(2, args.size())
                JLMetaVal.bool(when args[0] {
                    case number(a) = when args[1] {
                        case number(b) = a < b
                        else = throw ev.err("type error")
                    }
                    case string(a) = when args[1] {
                        case string(b) = a < b
                        else = throw ev.err("type error")
                    }
                    else = throw ev.err("type error")
                })
            },
        ))

    class Entry {
        val depth: Int
        val mutable: Bool
        var value: JLMetaVal
    }

    val depth: Int
    val parent: Nullable[Self]
    val table: Map[String, Entry] = Map()

    def(parent: Nullable[Self]): Self {
        if val p = parent {
            val scope = __malloc(p.depth + 1, null(p))
            for (name, f) in builtinFunctions.pairs() {
                scope.table[name] = Entry(0, false, JLMetaVal.builtin(f))
            }
            scope
        } else {
            __malloc(0, null)
        }
    }

    def getEntryOrNull(self, name: String): Nullable[Entry] {
        if val entry = table.getOrNull(name) {
            null(entry)
        } else if val p = parent {
            if val entry = p.getEntryOrNull(name) {
                table[name] = entry
                null(entry)
            } else {
                null
            }
        } else {
            null
        }
    }

    def getOrNull(self, name: String): Nullable[JLMetaVal] {
        if val entry = getEntryOrNull(name) {
            null(entry.value)
        } else {
            null
        }
    }

    def setOrMessage(self, name: String, value: JLMetaVal): Nullable[String] {
        if val entry = getEntryOrNull(name) {
            if entry.mutable {
                entry.value = value
                null
            } else {
                null("Meta variable " + name + " is not mutable")
            }
        } else {
            null("Meta variable " + name + " not found")
        }
    }

    def declareOrMessage(
            self, name: String, value: JLMetaVal, mutable: Bool): Nullable[String] {
        if val entry = table.getOrNull(name) {
            if entry.depth == depth {
                if entry.mutable {
                    entry.value = value
                    null
                } else {
                    if not entry.mutable {
                        null("Meta variable " + name + " is not mutable")
                    } else { null }
                }
            } else {
                table[name] = Entry(depth, mutable, value)
                null
            }
        } else {
            table[name] = Entry(depth, mutable, value)
            null
        }
    }
}
