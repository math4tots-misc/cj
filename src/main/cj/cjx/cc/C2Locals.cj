package cjx.cc

import cjx.parser.MError
import cjx.parser.Mark
import cjx.cc.C2IR.Var
import cjx.cc.C2IR.Type
import cjx.cc.C2IR.Taggable

class C2Locals {
    val list: List[Var] = []
    val maps: List[Map[String, Var]] = [MapOf()]
    val tagMaps: List[Map[String, Taggable]] = [MapOf()]

    def get(self, mark: Mark, name: String): Var {
        if val var_ = getOrNull(name) { var_ } else {
            throw MError("Variable " + name + " not found", [mark])
        }
    }

    def getOrNull(self, name: String): Var? {
        for i = maps.size() - 1; i >= 0; i-- {
            if val var_ = maps[i].getOrNull(name) {
                return null(var_)
            }
        }
        null
    }

    def add(self, mark: Mark, type: Type, name: String): Var {
        val map = maps.last()
        if val oldVar = map.getOrNull(name) {
            throw MError(
                "Variable " + name + " is already defined in this scope", [mark, oldVar.mark])
        }
        val index = list.size()
        val var_ = Var(mark, name, type, index)
        list.add(var_)
        map[name] = var_
        var_
    }

    def scoped[R](self, f: Fn[R]): R {
        maps.add(MapOf())
        tagMaps.add(MapOf())
        val ret = f.call()
        maps.pop()
        tagMaps.pop()
        ret
    }
}
