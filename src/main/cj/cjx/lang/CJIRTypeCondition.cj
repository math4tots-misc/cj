package cjx.lang

import cjx.lang.CJIRTrait
import cjx.lang.CJMark

@derive(new)
class CJIRTypeCondition {
    val mark: CJMark
    val name: String
    val traits: List[CJIRTrait]
}
