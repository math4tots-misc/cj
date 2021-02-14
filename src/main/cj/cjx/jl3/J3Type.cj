package cjx.jl3

import cjx.jl3.J3Class

@derive(repr)
union J3Type {
    case noreturn
    case void
    case bool
    case int
    case double
    case klass(J3Class)
    def isNoReturn(self): Bool = when self { case noreturn = true; else = false }
    def isVoid(self): Bool = when self { case void = true; else = false }
}
