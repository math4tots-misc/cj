package cjx.jl3

import cjx.jl3.J3Expr
import cjx.jl3.J3Type
import cjx.jl3.J3Local
import cjx.jl1.JLMark

class J3Method {
    val mark: JLMark
    val modifiers: List[String]
    val name: String
    val returnType: J3Type
    val parameters: List[J3Local] = []
    val body: Nullable[J3Expr] = null
    val locals: List[J3Local] = []

    def isStatic(self): Bool = "static" in modifiers

    def newLocal(self, modifiers: List[String], name: String, type: J3Type): J3Local {
        val id = locals.size()
        val local = J3Local(id, modifiers, name, type)
        locals.add(local)
        local
    }

    def addParam(self, modifiers: List[String], name: String, type: J3Type): J3Local {
        val local = newLocal(modifiers, name, type)
        parameters.add(local)
        local
    }
}
