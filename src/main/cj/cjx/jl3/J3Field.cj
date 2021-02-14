package cjx.jl3

import cjx.jl3.J3Type
import cjx.jl3.J3Mark

@derive(new)
class J3Field {
    val mark: J3Mark
    val modifiers: List[String]
    val name: String
    val type: J3Type
}
