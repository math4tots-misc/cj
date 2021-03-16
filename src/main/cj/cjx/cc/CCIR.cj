package cjx.cc

import cjx.parser.Mark

class CCIR {
    class Node {
        union Kind: Repr, Hash {
            case add
            case sub
            case mul
            case div
            case neg
            case int
            def repr(self): String = tag_names!(Self)[tag!(self)]
            def __eq(self, other: Self): Bool = self is other
            def hash(self): Int = tag!(self)
        }
        val mark: Mark
        val kind: Kind
        val args: List[Node] = []
        var intValue: Int = 0
        def __get_lhs(self): Node = args[0]
        def __get_rhs(self): Node = args[1]
        def __get_arg(self): Node = args[0]
    }

    class Foo {
        class Kind {
        }
    }
}
