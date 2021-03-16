package compiler

import cj.StringBuilder
import compiler.CJMark

class CJError : Repr {
    val message: String
    val stack: List[CJMark]

    def(message: String, stack: List[CJMark]): Self = __malloc(message, stack)

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
