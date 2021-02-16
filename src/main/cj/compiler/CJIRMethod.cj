package compiler

import compiler.CJIRExpression
import compiler.CJIRParameter
import compiler.CJIRType
import compiler.CJIRTypeCondition
import compiler.CJIRTypeParameter
import compiler.CJMark

class CJIRMethod {
    val mark: CJMark
    val name: String
    val conditions: List[CJIRTypeCondition] = []
    val typeParameters: List[CJIRTypeParameter] = []
    val parameters: List[CJIRParameter] = []
    var returnType: CJIRType = ?
    var body: Nullable[CJIRExpression] = null
}
