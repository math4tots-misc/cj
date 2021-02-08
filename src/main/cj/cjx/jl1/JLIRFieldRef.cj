package cjx.jl1

import cjx.jl1.JLIRField
import cjx.jl1.JLIRClass

## A field together with its declaring class
@derive(new)
class JLIRFieldRef {
    val owner: JLIRClass
    val field: JLIRField
}
