package cjx.n2

import cjx.n2.N2Error
import cjx.parser.Mark
import cjx.n2.N2IR.Var
import cjx.n2.N2IR.Type
import cjx.n2.N2IR.Expr

class N2Locals {
    val list: List[Var] = []
    val map: Map[String, Var] = MapOf()

    def add(self, mark: Mark, type: Type, name: String, init: Expr?): Var {
        val index = list.size()
        val var_ = Var(mark, type, name, index, init)
        list.add(var_)
        map[name] = var_
        var_
    }

    def getOrNull(self, name: String): Var? {
        map.getOrNull(name)
    }

    def get(self, mark: Mark, name: String): Var {
        if val var_ = getOrNull(name) { var_ } else {
            throw N2Error("Variable " + name + " not found", [mark])
        }
    }
}
