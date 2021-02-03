package cjx.lang

import cjx.lang.CJIRExpression
import cjx.lang.CJIRType
import cjx.lang.CJMark

@derive(new)
class CJIRField {
    val mark: CJMark
    val name: String
    val type: CJIRType
    var expression: Nullable[CJIRExpression] = null
}
