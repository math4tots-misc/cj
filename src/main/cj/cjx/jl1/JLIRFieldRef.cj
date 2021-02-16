package cjx.jl1

import cjx.jl1.JLIRField
import cjx.jl1.JLIRClass

## A field together with its declaring class
class JLIRFieldRef: ToString {
    val owner: JLIRClass
    val field: JLIRField

    def toString(self): String = owner.name + "." + field.name
}
