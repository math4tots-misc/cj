package cjx.jl3

import cjx.jl3.J3Data
import cjx.jl3.J3Field
import cjx.jl3.J3Method
import cjx.jl1.JLMark

@derive(new)
class J3Class: Repr {

    union Kind {
        case class_
        case interface_

        def isInterface(self): Bool = when self {
            case interface_ = true
            else = false
        }
    }

    val mark: JLMark
    val id: Int
    val kind: Kind
    val name: String
    var superClass: Nullable[J3Class] = null
    val interfaces: List[J3Class] = []
    val fields: List[J3Field] = []
    val methods: List[J3Method] = []
    var templateName: String = ""
    var templateArgs: List[J3Data] = []

    def repr(self): String = "<class " + name + " " + id + ">"
    def isInterface(self): Bool = kind.isInterface()
}
