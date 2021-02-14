package cjx.jl3

import cjx.jl3.J3Mark

class J3AstMetaExpr {
    union Data {
        case number(Double)
    }
    val mark: J3Mark
    val data: Data
}
