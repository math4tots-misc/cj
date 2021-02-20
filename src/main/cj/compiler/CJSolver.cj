package compiler

import compiler.CJError
import compiler.CJData
import compiler.CJScope
import compiler.CJAst
import compiler.CJIR

class CJSolver {

    class Task {
        val name: String
        val detail: String
        val f: Fn[Unit]
    }

    val sourceRoots: List[String]
    val todos: List[List[Task]] = []
    val itemMap: Map[String, CJIR.Item] = Map()

    def todo(self, level: Int, name: String, detail: String, f: Fn[Unit]) {
        while level >= todos.size() {
            todos.add([])
        }
        todos[level].add(Task(name, detail, f))
    }

    def solve(self) {
        var repeat = true
        while repeat {
            var i = 0
            while i < todos.size() and not todos[i] {
                i++
            }
            if i < todos.size() {
                todos[i].pop().f.call()
            } else {
                repeat = false
            }
        }
    }

    def addFile(self, file: CJAst.File) {
        val fileScope = CJScope.newRoot()
        val packageName = file.packageName
        for import_ in file.imports {
            fileScope.set(
                import_.mark,
                import_.alias,
                CJData.fullName(import_.fullName))
        }
        val fullName = packageName + "." + file.item.shortName
        addItem(fileScope, fullName, file.item)
    }

    private def addItem(self, outerScope: CJScope, fullName: String, item: CJAst.Item) {
        outerScope.set(item.mark, item.shortName, CJData.fullName(fullName))
        val itemScope = CJScope(outerScope)
        itemMap[fullName] = when item.kind {
            case class_ {
                val ircls = CJIR.Class(item.mark, item.comment, item.modifiers, fullName)
                CJIR.Item.class_(ircls)
            }
            case union_ {
                val irunion = CJIR.Union(item.mark, item.comment, item.modifiers, fullName)
                CJIR.Item.union_(irunion)
            }
            case trait_ = {
                val irtrait = CJIR.Trait(item.mark, item.comment, item.modifiers, fullName)
                CJIR.Item.trait_(irtrait)
            }
        }
        for member in item.members {
            when member {
                case item(subitem) = addItem(
                    itemScope, fullName + "$" + subitem.shortName, subitem)
                else = ()
            }
        }
    }
}
