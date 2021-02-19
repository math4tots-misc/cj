package compiler

import compiler.CJError
import compiler.CJMark
import compiler.CJData

class CJScope {
    val parent: Self?
    val map: Map[String, CJData] = Map()
    def(parent: Self): Self = __malloc(null(parent))
    def newRoot(): Self = __malloc(null)
    def set(self, mark: CJMark, key: String, data: CJData) {
        if key in map {
            throw CJError(key.repr() + " already defined in this scope", [mark])
        }
        map[key] = data
    }
    def getOrNull(self, key: String): CJData? {
        var scope = self
        while true {
            if val data = map.getOrNull(key) {
                return null(data)
            } else if val p = parent {
                scope = p
            } else {
                return null
            }
        }
    }
    def get(self, mark: CJMark, key: String): CJData {
        if val data = getOrNull(key) {
            data
        } else {
            throw CJError(key.repr() + " not defined in this scope", [mark])
        }
    }
}
