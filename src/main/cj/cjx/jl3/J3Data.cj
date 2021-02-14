package cjx.jl3

import cjx.jl3.J3Type

## Compile time data
@derive(repr)
union J3Data {
    case number(Double)
    case type(J3Type)
}
