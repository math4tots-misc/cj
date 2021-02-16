package compiler

import compiler.CJIRType
import compiler.CJIRItem
import compiler.CJMark

class CJIRTrait : Hash {
    val mark: CJMark
    val item: CJIRItem
    val args: List[CJIRType]

    def __eq(self, other: Self): Bool = item is other.item and args == other.args
    def hash(self): Int = (item.fullName, args).hash()
}
