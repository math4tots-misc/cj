package cjx.jl3

import cjx.jl3.J3Type

@derive(new)
class J3Local {
    val modifiers: List[String]
    val id: Int
    val name: String
    val type: J3Type

    def isMutable(self): Bool = "var" in modifiers
}
