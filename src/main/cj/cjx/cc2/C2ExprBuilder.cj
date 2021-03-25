package cjx.cc2

import cjx.cc2.C2Token
import cjx.parser.MError
import cjx.cc2.C2IR.Expr
import cjx.cc2.C2IR.Stmt
import cjx.cc2.C2IR.Var
import cjx.cc2.C2IR.Type
import cjx.parser.Mark

class C2ExprBuilder {

    # ========================================================================
    # Statements
    # ========================================================================

    def exprStmt(self, mark: Mark, expr: Expr): Stmt {
        val ret = Stmt(mark, Stmt.Kind.expr)
        ret.expr = expr
        ret
    }

    def ret(self, mark: Mark, expr: Expr): Stmt {
        val ret = Stmt(mark, Stmt.Kind.ret)
        ret.expr = expr
        ret
    }

    def block(self, mark: Mark, stmts: List[Stmt]): Stmt {
        val ret = Stmt(mark, Stmt.Kind.block)
        ret.stmts = stmts
        ret
    }

    # ========================================================================
    # Expressions
    # ========================================================================

    def int(self, mark: Mark, value: Int): Expr {
        val ret = Expr(mark, Expr.Kind.int)
        ret.intValue = value
        ret.type = Type.int
        ret
    }

    def getvar(self, mark: Mark, var_: Var): Expr {
        val ret = Expr(mark, Expr.Kind.getvar)
        ret.var_ = var_
        ret.type = var_.type
        ret
    }

    def binop(self, mark: Mark, type: Int, lhs: Expr, rhs: Expr): Expr {
        addType(lhs)
        addType(rhs)
        if lhs.type.isInt() and rhs.type.isInt() {
            switch type {
                case '+' { return genBinop(mark, Expr.Kind.intAdd, Type.int, lhs, rhs) }
                case '-' { return genBinop(mark, Expr.Kind.intSub, Type.int, lhs, rhs) }
                case '*' { return genBinop(mark, Expr.Kind.intMul, Type.int, lhs, rhs) }
                case '/' { return genBinop(mark, Expr.Kind.intDiv, Type.int, lhs, rhs) }
                case '%' { return genBinop(mark, Expr.Kind.intRem, Type.int, lhs, rhs) }
                else = ()
            }
        }
        throw MError("TODO eb.binop " + C2Token.typeRepr(type), [mark])
    }

    def preop(self, mark: Mark, type: Int, arg: Expr): Expr {
        addType(arg)
        if arg.type.isInt() {
            switch type {
                case '-' { return genUnop(mark, Expr.Kind.intNeg, Type.int, arg) }
                case '+' { return arg }
                else = ()
            }
        }
        throw MError("TODO eb.preop " + C2Token.typeRepr(type), [mark])
    }

    private def genUnop(self, mark: Mark, kind: Expr.Kind, type: Type, arg: Expr): Expr {
        val ret = Expr(mark, kind)
        ret.type = type
        ret.arg = arg
        ret
    }

    private def genBinop(
            self, mark: Mark, kind: Expr.Kind, type: Type, lhs: Expr, rhs: Expr): Expr {
        val ret = Expr(mark, kind)
        ret.type = type
        ret.lhs = lhs
        ret.rhs = rhs
        ret
    }

    def addType(expr: Expr) {
        val mark = expr.mark
        if not is_set!(expr, type) {
            when expr.kind {
                else name() = throw MError("TODO eb.addType " + expr.kind, [mark])
            }
        }
    }
}
