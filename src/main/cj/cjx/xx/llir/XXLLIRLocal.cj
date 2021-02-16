package cjx.xx.llir

import cjx.xx.llir.XXLLIRType
import cjx.xx.XXMark

class XXLLIRLocal {
    val mark: XXMark
    val id: Int
    val modifiers: List[String]
    val name: String
    val type: XXLLIRType
}
