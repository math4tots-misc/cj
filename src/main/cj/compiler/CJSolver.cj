package compiler

import compiler.CJData
import compiler.CJScope
import compiler.CJAst
import compiler.CJIR

class CJSolver {

    class Task {
        val name: String
        val f: Fn[Unit]
    }

    val todos: List[List[Task]] = []
    val itemMap: Map[String, CJIR.Item] = Map()

    def todo(self, level: Int, name: String, f: Fn[Unit]) {
        while level >= todos.size() {
            todos.add([])
        }
        todos[level].add(Task(name, f))
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
    }
}
