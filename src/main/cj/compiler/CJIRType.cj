package compiler

import compiler.CJIRTrait
import compiler.CJIRTypeParameter
import compiler.CJIRItem
import compiler.CJMark

class CJIRType : Hash {
    union Data {
        case item(CJIRItem, List[CJIRType])
        case variable(CJIRTypeParameter, List[CJIRTrait])
    }

    val mark: CJMark
    val data: Data

    def __eq(self, other: Self): Bool = when data {
        case item(item, args) = when other.data {
            case item(otherItem, otherArgs) = item is otherItem and args == otherArgs
            else = false
        }
        case variable(tparam, additionalTraits) = when other.data {
            case variable(otherTparam, otherAdditionalTraits) = tparam is otherTparam
            else = false
        }
    }

    def hash(self): Int = when data {
        case item(item, args) = (item.fullName, args).hash()
        case variable(tparam, additionalTraits) = tparam.name.hash()
    }
}
