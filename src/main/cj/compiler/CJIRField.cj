package compiler

import compiler.CJIRExpression
import compiler.CJIRType
import compiler.CJMark

class CJIRField {
    val mark: CJMark
    val name: String
    val type: CJIRType
    var expression: Nullable[CJIRExpression] = null
}
