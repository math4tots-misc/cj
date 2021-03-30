package compiler

import cj.StringBuilder
import cjx.parser.Mark

class CJError : Repr {
    val message: String
    val stack: List[Mark]

    def(message: String, stack: List[Mark]): Self = __malloc(message, stack)

    def repr(self): String = "CJError(" + message + ", " + stack.repr() + ")"

    def toString(self): String = {
        val sb = StringBuilder()
        sb.add(message + "\n")
        for mark in stack {
            sb.add("  " + mark + "\n")
        }
        sb.toString()
    }
}
