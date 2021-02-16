package compiler

import compiler.CJIRField
import compiler.CJIRMethod
import compiler.CJMark

class CJIRItem {

    union Kind {
        case class_
        case union_
        case trait_
    }

    val mark: CJMark
    val kind: Kind
    val packageName: String
    val shortName: String
    val fullName: String
    val methods: List[CJIRMethod] = []
    val fields: List[CJIRField] = []

    def new(mark: CJMark, kind: Kind, packageName: String, shortName: String): Self = (
        __malloc(mark, kind, packageName, shortName, packageName + "." + shortName))
}
