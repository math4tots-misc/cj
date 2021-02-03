package cjx.lang

import cjx.lang.CJIRMethod
import cjx.lang.CJIRTrait
import cjx.lang.CJIRType


## Method together with the type or trait whose item body defined this method.
class CJIRBoundMethod {
    union Owner {
        case type(CJIRType)
        case trait_(CJIRTrait)
    }

    val owner: Owner
    val method: CJIRMethod
}
