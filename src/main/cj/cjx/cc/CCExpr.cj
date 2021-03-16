package cjx.cc

import cjx.cc.CCMark

class CCExpr {
    union Kind: Repr, Eq, Hash {
        case iadd
        case isub
        case imul
        case idiv
        case ineg
        case int
        def repr(self): String = when self { else name() = name }
        def __eq(self, other: Self): Bool = tag!(self) == tag!(other)
        def hash(self): Int = tag!(self).hash()
    }

    val mark: CCMark
    val kind: Kind
    val args: List[CCExpr] = []
    var intValue: Int = 0

    def __get_lhs(self): CCExpr = args[0]
    def __get_rhs(self): CCExpr = args[1]
}
