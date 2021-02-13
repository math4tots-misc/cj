package cjx.jl3

import cjx.jl3.J3Class

@derive(repr)
union J3Type {
    case noreturn
    case void
    case int
    case double
    case klass(J3Class)
}
