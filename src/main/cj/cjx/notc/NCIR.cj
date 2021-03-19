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

    union Type: Repr, Eq {
        case unreachable
        case void
        case int
        def isUnreachable(self): Bool = tag!(self) == tag!(Type, unreachable)
        def isVoid(self): Bool = tag!(self) == tag!(Type, void)
        def isInt(self): Bool = tag!(self) == tag!(Type, int)
        def size(self): Int = when self {
            case unreachable = 0
            case void = NCIR.ptrSize
            case int = NCIR.ptrSize
        }
        def repr(self): String = tag_name!(self)
        def __eq(self, other: Self): Bool = tag!(self) == tag!(other) and switch tag!(self) {
            else = true
        }
        def common(mark: Mark, a: Self, b: Self): Self {
            if a.isVoid() or b.isVoid() {
                void
            } else if a.isUnreachable() {
                b
            } else if b.isUnreachable() {
                a
            } else if a == b {
                a
            } else {
                throw NCError("Types " + a + " and " + b + " are not compatiable", [mark])
            }
        }
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

            kGETVAR
            kSETVAR

            kIF
            kWHILE

            kRETURN

            kBLOCK
        }

        private static val kindNames: List[String] = static_field_names!(Self, "k[A-Z_]+")

        val mark: Mark
        val kind: Int
        var type: Type

        # literals
        var intValue: Int = ?

        # variable
        var var_: Var = ?

        # binops/unops
        var lhs: Expr = ?
        var rhs: Expr = ?
        def __get_arg(self): Expr = lhs
        def __set_arg(self, value: Expr) { lhs = value }

        # if/while
        var cond: Expr = ?
        var then: Expr = ?
        var els: Expr = ?

        # block
        var stmts: List[Expr] = ?

        def int(mark: Mark, value: Int): Self {
            val self = Self(mark, kINT, Type.int)
            self.intValue = value
            self
        }

        def getvar(mark: Mark, var_: Var): Self {
            val self = Self(mark, kGETVAR, var_.type)
            self.var_ = var_
            self
        }

        def setvar(mark: Mark, var_: Var, valexpr: Expr): Self {
            val self = unop(mark, kSETVAR, var_.type, valexpr)
            self.var_ = var_
            self
        }

        def assign(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.kind == kGETVAR {
                return setvar(mark, lhs.var_, rhs)
            }
            throw NCError(kindNames[lhs.kind] + " is not assignable", [mark])
        }

        def if_(mark: Mark, cond: Expr, then: Expr, els: Expr): Self {
            if not cond.type.isInt() {
                throw NCError("'if' condition should be an int, but got " + cond.type, [mark])
            }
            val type = Type.common(mark, cond.type, els.type)
            val self = Self(mark, kIF, type)
            self.cond = cond
            self.then = then
            self.els = els
            self
        }

        def while_(mark: Mark, cond: Expr, then: Expr): Self {
            if not cond.type.isInt() {
                throw NCError("'while' condition should be an int, but got " + cond.type, [mark])
            }
            val self = Self(mark, kWHILE, Type.void)
            self.cond = cond
            self.then = then
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

        def ret(mark: Mark, expr: Expr): Self {
            return unop(mark, kRETURN, Type.unreachable, expr)
        }

        def block(mark: Mark, stmts: List[Expr]): Self {
            val type = if stmts { stmts.last().type } else { Type.void }
            val block = Expr(mark, kBLOCK, type)
            block.stmts = stmts
            block
        }

        def nop(mark: Mark): Self = block(mark, [])

        def repr(self): String {
            val kindstr = kindNames[kind]
            switch kind {
                else = kindstr
            }
        }
    }
}
