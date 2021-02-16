package cjx.lang

import cjx.lang.CJIRExpression
import cjx.lang.CJIRParameter
import cjx.lang.CJIRType
import cjx.lang.CJIRTypeCondition
import cjx.lang.CJIRTypeParameter
import cjx.lang.CJMark

class CJIRMethod {
    val mark: CJMark
    val name: String
    val conditions: List[CJIRTypeCondition] = []
    val typeParameters: List[CJIRTypeParameter] = []
    val parameters: List[CJIRParameter] = []
    var returnType: CJIRType = ?
    var body: Nullable[CJIRExpression] = null
}
