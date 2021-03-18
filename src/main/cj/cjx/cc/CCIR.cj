package cjx.cc

import cj.Error
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

    ## variable
    class Obj {
        val name: String
        val id: Int
    }

    class Node: Repr {
        union Kind: Repr, Hash {
            static val binops: Set[Kind] = SetOf(
                add, sub, mul, div, rem, eq, ne, lt, le, assign)

            static val unops: Set[Kind] = SetOf(neg, pos, exprStmt)

            case add
            case sub
            case mul
            case div
            case rem
            case pos
            case neg
            case eq
            case ne
            case lt
            case le
            case assign
            case return_
            case exprStmt  # expression statement
            case var_
            case int
            def repr(self): String = tag_name!(self)
            def __eq(self, other: Self): Bool = self is other
            def hash(self): Int = tag!(self)
            def isUnop(self): Bool = self in unops
            def isBinop(self): Bool = self in binops
        }

        @implicit(Int, int)
        @implicit(String, string)
        union Value {
            case int(Int)
            case string(String)
        }

        val mark: Mark
        val kind: Kind

        # binops
        var lhs: Node = ?
        var rhs: Node = ?

        # unops
        def __set_arg(self, node: Node) { lhs = node }
        def __get_arg(self): Node = lhs

        # var
        var var_: Obj = ?

        # literal value
        var value: Value = ?
        def __get_intValue(self): Int = get!(value, int, 0)
        def __get_stringValue(self): String = get!(value, string, 0)

        def repr(self): String = when kind {
            case var_ = "var(" + var_.name + "," + var_.id + ")"
            case int = "int(" + intValue + ")"
            else = if kind.isBinop() {
                kind.repr() + "(" + lhs + "," + rhs + ")"
            } else if kind.isUnop() {
                kind.repr() + "(" + arg + ")"
            } else {
                kind.repr()
            }
        }
    }
}
