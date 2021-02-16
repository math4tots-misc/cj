package cjx.jl3

import cjx.jl3.J3Expr
import cjx.jl3.J3Local
import cjx.jl3.J3Type
import cjx.jl3.J3Mark

class J3Method {
    val mark: J3Mark
    val modifiers: List[String]
    val name: String
    val returnType: J3Type
    val parameters: List[J3Local] = []
    val locals: List[J3Local] = []
    val body: Nullable[J3Expr] = null

    def newLocal(self, mark: J3Mark, modifiers: List[String], name: String, type: J3Type): J3Local {
        val id = locals.size()
        val local = J3Local(mark, id, modifiers, name, type)
        locals.add(local)
        local
    }

    def addParam(self, mark: J3Mark, modifiers: List[String], name: String, type: J3Type) {
        parameters.add(newLocal(mark, modifiers, name, type))
    }
}
