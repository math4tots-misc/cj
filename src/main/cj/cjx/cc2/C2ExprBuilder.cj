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
        switch type {
            else = throw MError("TODO eb.binop " + C2Token.typeRepr(type), [mark])
        }
    }

    def preop(self, mark: Mark, type: Int, arg: Expr): Expr {
        addType(arg)
        switch type {
            case '-' {
                when arg.type {
                    case int = intNeg(mark, arg)
                    else = throw MError(
                        "unary '-' operator is not supported for " + arg.type, [mark])
                }
            }
            else = throw MError("TODO eb.preop " + C2Token.typeRepr(type), [mark])
        }
    }

    def intNeg(self, mark: Mark, expr: Expr): Expr {
        val ret = Expr(mark, Expr.Kind.intNeg)
        ret.arg = expr
        ret.type = Type.int
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
