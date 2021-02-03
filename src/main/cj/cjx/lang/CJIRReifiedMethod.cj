package cjx.lang

import cjx.lang.CJIRType
import cjx.lang.CJIRBoundMethod

## Bound method together with the type arguments for this method
class CJIRReifiedMethod {
    val boundMethod: CJIRBoundMethod
    val typeArgs: List[CJIRType]
}
