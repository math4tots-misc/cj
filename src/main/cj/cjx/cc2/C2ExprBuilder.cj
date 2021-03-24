package cjx.cc2

import cjx.cc2.C2Token
import cjx.parser.MError
import cjx.cc2.C2IR.Expr
import cjx.cc2.C2IR.Stmt
import cjx.cc2.C2IR.Var
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
        ret
    }

    def getvar(self, mark: Mark, var_: Var): Expr {
        val ret = Expr(mark, Expr.Kind.getvar)
        ret.var_ = var_
        ret
    }

    def binop(self, mark: Mark, type: Int, left: Expr, right: Expr): Expr {
        switch type {
            else = throw MError("TODO binop " + C2Token.typeRepr(type), [mark])
        }
    }
}
