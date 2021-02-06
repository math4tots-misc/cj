package cjx.jl1

import cjx.jl1.JLType
import cjx.jl1.JLMark

@derive(new)
class JLIRLocal {
    val mark: JLMark

    ## An id unique within the function in which it is defined
    val id: Int

    ## The variable's name
    val name: String

    ## The type of this variable
    val type: JLType
}
