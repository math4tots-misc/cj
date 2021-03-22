package cjx.n2

import cj.StringBuilder
import cjx.parser.Mark

class N2Error {
    val message: String
    val stack: List[Mark]

    def(message: String, stack: List[Mark]): Self = __malloc(message, stack)

    def repr(self): String = "N2Error(" + message + ", " + stack.repr() + ")"

    def toString(self): String = {
        val sb = StringBuilder()
        sb.add(message + "\n")
        for mark in stack {
            sb.add("  " + mark + "\n")
        }
        sb.toString()
    }
}
