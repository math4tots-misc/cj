package cjx.jl3

import cjx.jl3.J3Type

@derive(new)
class J3Local {
    val id: Int
    val modifiers: List[String]
    val name: String
    val type: J3Type

    def isMutable(self): Bool = "var" in modifiers
}
