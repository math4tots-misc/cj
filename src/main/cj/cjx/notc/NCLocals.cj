package cjx.notc

import cjx.notc.NCError
import cjx.parser.Mark
import cjx.notc.NCIR.Var
import cjx.notc.NCIR.Type

class NCLocals {
    val list: List[Var] = []
    val map: Map[String, Var] = MapOf()

    def add(self, mark: Mark, type: Type, name: String): Var {
        val index = list.size()
        val var_ = Var(mark, type, name, index)
        list.add(var_)
        map[name] = var_
        var_
    }

    def getOrNull(self, name: String): Var? {
        map.getOrNull(name)
    }

    def get(self, mark: Mark, name: String): Var {
        if val var_ = getOrNull(name) { var_ } else {
            throw NCError("Variable " + name + " not found", [mark])
        }
    }
}
