package cjx.cc

import cjx.parser.MError
import cjx.parser.Mark
import cjx.cc.C2IR.Var
import cjx.cc.C2IR.Type
import cjx.cc.C2IR.Taggable
import cjx.cc.C2IR.Ordinary
import cjx.cc.C2IR.Typedef
import cjx.cc.C2IR.EnumConstant

class C2Locals {
    val list: List[Var] = []
    val maps: List[Map[String, Ordinary]] = [MapOf()]
    val tagMaps: List[Map[String, Taggable]] = [MapOf()]

    def get(self, mark: Mark, name: String): Ordinary {
        if val ordinary = getOrNull(name) { ordinary } else {
            throw MError("Name '" + name + "' not found", [mark])
        }
    }

    def getOrNull(self, name: String): Ordinary? {
        for i = maps.size() - 1; i >= 0; i-- {
            if val var_ = maps[i].getOrNull(name) {
                return null(var_)
            }
        }
        null
    }

    def addEnumConstant(self, ec: EnumConstant) {
        _add(ec.mark, ec.name, ec)
    }

    def addTypedef(self, typedef: Typedef) {
        _add(typedef.mark, typedef.name, typedef)
    }

    def addLVar(self, mark: Mark, type: Type, name: String): Var {
        val index = list.size()
        val var_ = Var(mark, name, type, index)
        _add(mark, name, var_)
        list.add(var_)
        var_
    }

    def _add(self, mark: Mark, name: String, ordinary: Ordinary) {
        val map = maps.last()
        if val old = map.getOrNull(name) {
            throw MError(
                "'" + name + "' is already defined in this scope", [mark])
        }
        map[name] = ordinary
    }

    def scoped(self, f: Fn[Unit]): List[Var] {
        maps.add(MapOf())
        tagMaps.add(MapOf())
        f.call()
        val vars = maps.pop().values().flatMap(ordinary -> {
            when ordinary {
                case lvar(v) = [v].iter()
                else = List[Var].empty().iter()
            }
        }).sortedBy(v -> v.index)
        tagMaps.pop()
        vars
    }
}
