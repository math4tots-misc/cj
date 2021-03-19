package cjx.parser

import cj.StringBuilder
import cjx.parser.Mark

## Error with Mark information
class MError {
    val message: String
    val stack: List[Mark]

    def(message: String, stack: List[Mark]): Self = __malloc(message, stack)

    def repr(self): String = "MError(" + message + ", " + stack.repr() + ")"

    def toString(self): String = {
        val sb = StringBuilder()
        sb.add(message + "\n")
        for mark in stack {
            sb.add("  " + mark + "\n")
        }
        sb.toString()
    }
}
