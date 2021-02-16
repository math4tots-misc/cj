package cjx.lang

import cjx.lang.CJIRExpression
import cjx.lang.CJIRType
import cjx.lang.CJMark

class CJIRField {
    val mark: CJMark
    val name: String
    val type: CJIRType
    var expression: Nullable[CJIRExpression] = null
}
