package cjx.jx

import cjx.jx.JXTaskManager
import cjx.jx.JXJSGen
import cj.StringBuilder
import compiler.CJError
import compiler.CJMark
import cjx.jx.JXData

class JXScope {

    class Cell {
        val depth: Int
        val data: JXData
    }

    val depth: Int
    val parent: JXScope?
    val map: Map[String, Cell] = Map()
    def(parent: JXScope): Self = __malloc(parent.depth + 1, null(parent))
    def newRoot(): Self = __malloc(0, null)
    def set(self, mark: CJMark, key: String, data: JXData) {
        if val cell = map.getOrNull(key) {
            if cell.depth == depth {
                throw CJError(key.repr() + " is already defined in this scope", [mark])
            }
        }
        map[key] = Cell(depth, data)
    }
    def _getCellOrNull(self, key: String): Cell? {
        if val cell = map.getOrNull(key) {
            null(cell)
        } else if val p = parent {
            if val cell = p._getCellOrNull(key) {
                map[key] = cell
                null(cell)
            } else { null }
        } else { null }
    }
    def getOrNull(self, key: String): JXData? {
        if val cell = _getCellOrNull(key) { null(cell.data) } else { null }
    }
    def get(self, mark: CJMark, key: String): JXData {
        if val data = getOrNull(key) {
            data
        } else {
            throw CJError(key.repr() + " not found in this scope", [mark])
        }
    }
    def getString(self, mark: CJMark, key: String): String {
        when get(mark, key) {
            case string(s) = s
            else = throw CJError(key.repr() + " is not a string", [mark])
        }
    }
    def getStringList(self, mark: CJMark, key: String): List[String] {
        when get(mark, key) {
            case stringList(s) = s
            else = throw CJError(key.repr() + " is not a string list", [mark])
        }
    }
    def getCodeGen(self, mark: CJMark, key: String): JXJSGen {
        when get(mark, key) {
            case codeGen(s) = s
            else = throw CJError(key.repr() + " is not a code-generator", [mark])
        }
    }
    def getTaskManager(self, mark: CJMark, key: String): JXTaskManager {
        when get(mark, key) {
            case taskManager(s) = s
            else = throw CJError(key.repr() + " is not a task manager", [mark])
        }
    }
}
