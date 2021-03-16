package cjx.cc

import cj.StringBuilder
import cjx.cc.CCMark
import cj.Error

class CCError {
    val error: Error
    val stack: List[CCMark]

    def(message: String, stack: List[CCMark]): Self = __malloc(Error(message), stack)

    def repr(self): String = "CCError(" + error.message() + ", " + stack.repr() + ")"

    def toString(self): String = {
        val sb = StringBuilder()
        sb.add(error.message() + "\n")
        for mark in stack {
            sb.add("  " + mark + "\n")
        }
        sb.toString()
    }
}
