package cjx.lang

import cjx.lang.CJIRType
import cjx.lang.CJIRItem
import cjx.lang.CJMark

class CJIRTrait : Hash {
    val mark: CJMark
    val item: CJIRItem
    val args: List[CJIRType]

    def __eq(self, other: Self): Bool = item is other.item and args == other.args
    def hash(self): Int = (item.fullName, args).hash()
}
