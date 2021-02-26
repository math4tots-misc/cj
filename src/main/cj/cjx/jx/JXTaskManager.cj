package cjx.jx

import cj.Deque

class JXTaskManager {
    class Task: Repr {
        val name: String
        val detail: String
        val f: Fn[Unit]
        def repr(self): String = "Task(" + name + "," + detail + ")"
    }

    val todos: List[Deque[Task]] = []
    var verbose = false

    def todo(self, level: Int, name: String, detail: String, f: Fn[Unit]) {
        while level >= todos.size() {
            todos.add(Deque())
        }
        todos[level].add(Task(name, detail, f))
    }

    def run(self) {
        var repeat = true
        while repeat {
            var i = 0
            while i < todos.size() and not todos[i] {
                i++
            }
            if i < todos.size() {
                val task = todos[i].popleft()
                if verbose {
                    IO.println(task)
                }
                task.f.call()
            } else {
                repeat = false
            }
        }
    }
}
