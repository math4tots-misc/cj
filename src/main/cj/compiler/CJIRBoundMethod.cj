package compiler

import compiler.CJIRMethod
import compiler.CJIRTrait
import compiler.CJIRType


## Method together with the type or trait whose item body defined this method.
class CJIRBoundMethod {
    union Owner {
        case type(CJIRType)
        case trait_(CJIRTrait)
    }

    val owner: Owner
    val method: CJIRMethod
}
