package cjx.cc

import cj.Error
import cjx.parser.Mark

class CCIR {

    # wasm32 uses 4-byte pointers
    static val ptrSize = 4

    class Type: Eq, Repr {
        static val int: Self = Self(Kind.int)

        def ptr(ty: Self): Self {
            val self = Self(Kind.ptr)
            self.base = ty
            self
        }

        def func(returnType: Self, params: List[Tuple[Mark, Type, String]]): Self {
            val self = Self(Kind.func)
            self.returnType = returnType
            self.params = params
            self
        }

        union Kind: Eq {
            case int
            case ptr
            case func
            def __eq(self, other: Self): Bool = self is other
        }
        val kind: Kind
        var base: Type = ?

        # functions
        def __get_returnType(self): Type = base
        def __set_returnType(self, returnType: Type) { base = returnType }
        var params: List[Tuple[Mark, Type, String]] = ?
        def __get_paramTypes(self): List[Type] = params.map(p -> p.f1)

        def isPtr(self): Bool = tag!(kind) == tag!(Kind, ptr)
        def isInt(self): Bool = tag!(kind) == tag!(Kind, int)

        def __eq(self, other: Self): Bool {
            val tag = tag!(kind)
            if tag != tag!(other.kind) {
                return false
            }
            switch tag {
                case tag!(Kind, ptr) = base == other.base
                else = true
            }
        }

        def repr(self): String = when kind {
            case int = "int"
            case ptr = "ptr(" + base + ")"
            case func = "func(" + returnType + ")"
        }
    }

    class Func {
        val mark: Mark
        val name: String
        val type: Type
        var locals: List[Obj] = []
        var body: Node = ?
        def __get_params(self): List[Obj] = locals[:type.params.size()]
    }

    ## variable
    class Obj {
        val name: String
        val offset: Int   # offset for the location of this local variable
        val type: Type
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
            case addr
            case deref
            case return_
            case if_
            case for_
            case block
            case funcall
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

        var type: Type = ?

        # block
        var body: List[Node] = ?

        # binops
        var lhs: Node = ?
        var rhs: Node = ?

        # if or for
        var cond: Node = ?
        var then: Node = ?
        var els: Node = ?
        var init: Node = ?
        var inc: Node = ?

        # unops
        def __set_arg(self, node: Node) { lhs = node }
        def __get_arg(self): Node = lhs

        # function call
        var func: Func = ?
        def __set_args(self, args: List[Node]) { body = args }
        def __get_args(self): List[Node] = body

        # var
        var var_: Obj = ?

        # literal value
        var value: Value = ?
        def __get_intValue(self): Int = get!(value, int, 0)
        def __get_stringValue(self): String = get!(value, string, 0)

        def repr(self): String = when kind {
            case var_ = "var(" + var_.name + "," + var_.offset + ")"
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
