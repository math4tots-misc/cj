package cjx.lang

import cjx.lang.CJIRReifiedMethod
import cjx.lang.CJIRType
import cjx.lang.CJMark

class CJIRExpression {
    union Data {
        case unit
        case call(CJIRType, CJIRReifiedMethod, List[CJIRExpression])
        case block(List[CJIRExpression])
    }

    val mark: CJMark
    val type: CJIRType
    val data: Data
}
