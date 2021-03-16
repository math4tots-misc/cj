package cjx.cc

import cjx.parser.Mark

class CCIR {

    class Type {
        union Kind {
            case int
            case ptr
        }
        val kind: Kind
        var base: Type = ?
    }

    class Node {
        union Kind: Repr, Hash {
            case add
            case sub
            case mul
            case div
            case pos
            case neg
            case int
            def repr(self): String = tag_name!(self)
            def __eq(self, other: Self): Bool = self is other
            def hash(self): Int = tag!(self)
        }
        val mark: Mark
        val kind: Kind

        # binops
        var lhs: Node = ?
        var rhs: Node = ?

        # unops
        def __set_arg(self, node: Node) { lhs = node }
        def __get_arg(self): Node = lhs

        # case int
        var intValue: Int = ?
    }
}
