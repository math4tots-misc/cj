package compiler

import compiler.CJIRType
import compiler.CJIRBoundMethod

## Bound method together with the type arguments for this method
class CJIRReifiedMethod {
    val boundMethod: CJIRBoundMethod
    val typeArgs: List[CJIRType]
}
