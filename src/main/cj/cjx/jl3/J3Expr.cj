package cjx.jl3

import cjx.jl3.J3Local
import cjx.jl3.J3Type
import cjx.jl3.J3Mark

class J3Expr {
    union Data {
        case int(Int)
        case lambda(List[J3Local], List[J3Local], J3Expr)
    }
    val mark: J3Mark
    val type: J3Type
    val data: Data
    val terminatesFlow: Bool

    def __new(mark: J3Mark, type: J3Type, data: Data): Self {
        __malloc(mark, type, data, if type.isNoReturn() { true } else { false })
    }
}
