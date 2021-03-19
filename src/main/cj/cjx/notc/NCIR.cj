package cjx.notc

import cjx.notc.NCError
import cjx.parser.Mark

class NCIR {
    static val ptrSize = 4

    class Program {
        val funcs: List[Func] = []
    }

    class Var {
        val mark: Mark
        val type: Type
        val name: String
        val index: Int
    }

    class Func {
        val mark: Mark
        val returnType: Type
        val name: String
        val nparams: Int
        val locals: List[Var]
        var body: Expr = ?
        def __get_params(self): List[Var] = locals[:nparams]
    }

    union Type: Repr {
        case int
        def isInt(self): Bool = tag!(self) == tag!(Type, int)
        def size(self): Int = when self {
            case int = NCIR.ptrSize
        }
        def repr(self): String = tag_name!(self)
    }

    class Expr: Repr {
        enum { # expression kinds
            kINT
            kINT_ADD
            kINT_SUB
            kINT_MUL
            kINT_DIV
            kINT_NEG
            kINT_EQ
            kINT_NE
            kINT_LT
            kINT_LE
        }

        private static val kindNames: List[String] = static_field_names!(Self, "k[A-Z_]+")

        val mark: Mark
        val kind: Int
        var type: Type
        var intValue: Int = ?
        var lhs: Expr = ?
        var rhs: Expr = ?
        def __get_arg(self): Expr = lhs
        def __set_arg(self, value: Expr) { lhs = value }

        def int(mark: Mark, value: Int): Self {
            val self = Self(mark, kINT, Type.int)
            self.intValue = value
            self
        }

        private def binop(mark: Mark, kind: Int, type: Type, lhs: Expr, rhs: Expr): Expr {
            val expr = Expr(mark, kind, type)
            expr.lhs = lhs
            expr.rhs = rhs
            expr
        }

        private def unop(mark: Mark, kind: Int, type: Type, arg: Expr): Expr {
            val expr = Expr(mark, kind, type)
            expr.arg = arg
            expr
        }

        def neg(mark: Mark, arg: Expr): Self {
            if arg.type.isInt() {
                if arg.kind == kINT {
                    return int(mark, -arg.intValue)
                } else {
                    return unop(mark, kINT_NEG, Type.int, arg)
                }
            }
            throw NCError(
                "Invalid args to unary '-' (" + arg.type + ")", [mark])
        }

        def pos(mark: Mark, arg: Expr): Self {
            if arg.type.isInt() {
                return arg
            }
            throw NCError(
                "Invalid args to unary '-' (" + arg.type + ")", [mark])
        }

        def add(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_ADD, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '+' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def sub(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_SUB, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '-' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def mul(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_MUL, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '*' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def div(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_DIV, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '/' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def eq(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_EQ, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '==' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def ne(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_NE, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '!=' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def lt(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_LT, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '<' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def le(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_LE, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '<=' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def repr(self): String {
            val kindstr = kindNames[kind]
            switch kind {
                else = kindstr
            }
        }
    }
}
