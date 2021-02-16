package cjx.xx.llir

@derive(repr)
union XXLLIRType: Eq {
    case noreturn
    case void
    case unit
    case bool
    case int
    case double
    case klass(String)
    def __eq(self, other: Self): Bool = repr() == other.repr()
    def isNoReturn(self): Bool = when self { case noreturn = true; else = false }
    def isVoid(self): Bool = when self { case void = true; else = false }
    def isUnit(self): Bool = when self { case unit = true; else = false }
}
