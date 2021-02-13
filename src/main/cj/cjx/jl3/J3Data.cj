package cjx.jl3

import cjx.jl3.J3Class
import cjx.jl1.JLMark
import cjx.jl3.J3Type

union J3Data : Repr {
    case type(J3Type)
    case classTemplate(Fn[JLMark, List[J3Data], J3Data])

    def repr(self): String = when self {
        case type(t) = t.repr()
        case classTemplate(f) = "<class-template>"
    }
}
