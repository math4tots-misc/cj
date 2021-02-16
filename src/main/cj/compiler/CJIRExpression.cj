package compiler

import compiler.CJIRReifiedMethod
import compiler.CJIRType
import compiler.CJMark

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
