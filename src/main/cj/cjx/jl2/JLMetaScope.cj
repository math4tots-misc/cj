package cjx.jl2

import cjx.jl1.JLError
import cjx.jl2.JLMetaVal

class JLMetaScope {

    @derive(new)
    class Entry {
        val depth: Int
        val mutable: Bool
        var value: JLMetaVal
    }

    val depth: Int
    val parent: Nullable[Self]
    val table: Map[String, Entry] = Map()

    def new(parent: Nullable[Self]): Self {
        if null(p) = parent {
            __malloc(p.depth + 1, null(p))
        } else {
            __malloc(0, null)
        }
    }

    def getEntryOrNull(self, name: String): Nullable[Entry] {
        if null(entry) = table.getOrNull(name) {
            null(entry)
        } else if null(p) = parent {
            if null(entry) = p.getEntryOrNull(name) {
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
        if null(entry) = getEntryOrNull(name) {
            null(entry.value)
        } else {
            null
        }
    }

    def setOrMessage(self, name: String, value: JLMetaVal): Nullable[String] {
        if null(entry) = getEntryOrNull(name) {
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
        if null(entry) = table.getOrNull(name) {
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
