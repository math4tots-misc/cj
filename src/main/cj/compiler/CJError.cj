package compiler

import cj.StringBuilder
import compiler.CJMark
import cj.Error

class CJError : Repr {
    val error: Error
    val stack: List[CJMark]

    def new(message: String, stack: List[CJMark]): Self = __malloc(Error(message), stack)

    def repr(self): String = "CJError(" + error.message() + ", " + stack.repr() + ")"

    def toString(self): String = {
        val sb = StringBuilder()
        sb.add(error.message() + "\n")
        for mark in stack {
            sb.add("  " + mark + "\n")
        }
        sb.toString()
    }
}
