package cjx.xx.llir

import cjx.xx.llir.XXLLIRType
import cjx.xx.XXMark

class XXLLIRField {
    val mark: XXMark
    val modifiers: List[String]
    val name: String
    val type: XXLLIRType
    def isStatic(self): Bool = "static" in modifiers
    def isMutable(self): Bool = "var" in modifiers
}
