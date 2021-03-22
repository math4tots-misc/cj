package cjx.cc

import cjx.cc.CCError
import cjx.parser.Mark
import cjx.cc.CCIR.Obj
import cjx.cc.CCIR.Type

class CCLocals {
    var list: List[Obj] = []
    var map: Map[String, Obj] = MapOf()
    var nextOffset: Int = 0

    def get(self, name: String, mark: Mark): Obj {
        if val obj = map.getOrNull(name) {
            obj
        } else {
            throw CCError("Variable '" + name + "' not found", [mark])
        }
    }

    def add(self, mark: Mark, type: Type, name: String): Obj {
        val offset = nextOffset
        nextOffset += 4

        val obj = Obj(name, offset, type)
        map[name] = obj
        list.add(obj)
        obj
    }
}
