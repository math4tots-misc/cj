package compiler

import compiler.CJMark

class CJAstItem {
    union Member {
        case item(CJAstItem)
    }

    val mark: CJMark
    val packageName: String
    val comment: Nullable[String]
    val name: String
    val members: List[Member]
}
