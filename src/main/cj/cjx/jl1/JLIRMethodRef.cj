package cjx.jl1

import cjx.jl1.JLIRClass
import cjx.jl1.JLIRMethod

## A method together with the class or interface in which it is declared
##
## This allows us to determine if the given method reference is a class
## method or an interface method.
##
class JLIRMethodRef: ToString {
    val owner: JLIRClass
    val method: JLIRMethod

    def toString(self): String = owner.name + "." + method.name
}
