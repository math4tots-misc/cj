package cjx.jl3

import cjx.jl1.JLMark

@derive(new)
class J3Expr {

    union Data {
    }

    val mark: JLMark
    val data: Data
}
