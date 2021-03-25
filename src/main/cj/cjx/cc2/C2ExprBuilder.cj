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

    def nop(self, mark: Mark): Stmt = Stmt(mark, Stmt.Kind.nop)

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
        val newStmts: List[Stmt] = []
        for stmt in stmts {
            when stmt.kind {
                case nop = ()
                case block = newStmts.addAll(stmt.stmts)
                else = newStmts.add(stmt)
            }
        }
        switch newStmts.size() {
            case 0 = nop(mark)
            case 1 = newStmts[0]
            else {
                val ret = Stmt(mark, Stmt.Kind.block)
                ret.stmts = newStmts
                ret
            }
        }
    }

    def if_(self, mark: Mark, cond: Expr, then: Stmt, els: Stmt): Stmt {
        val ret = Stmt(mark, Stmt.Kind.if_)
        ret.cond = castTruthy(cond)
        ret.then = then
        ret.els = els
        ret
    }

    def for_(self, mark: Mark, init: Stmt, cond: Expr, incr: Expr, then: Stmt): Stmt {
        block(mark, [
            init,
            while_(mark, cond, block(mark, [
                then,
                exprStmt(mark, incr),
            ])),
        ])
    }

    def while_(self, mark: Mark, cond: Expr, then: Stmt): Stmt {
        val ret = Stmt(mark, Stmt.Kind.while_)
        ret.cond = castTruthy(cond)
        ret.then = then
        ret
    }

    # ========================================================================
    # Expressions
    # ========================================================================

    ## Implicit cast an expression to a given type
    def icast(self, expr: Expr, type: Type): Expr {
        addType(expr)
        if expr.type != type {
            throw MError("Expected " + type + " but got " + expr.type, [expr.mark])
        }
        expr
    }

    def castTruthy(self, expr: Expr): Expr {
        addType(expr)
        when expr.type {
            case int
            case ptr(p) = expr
            else = throw MError(
                "Expected truthy value but got " + expr.type, [expr.mark])
        }
    }

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

    def setvar(self, mark: Mark, var_: Var, arg: Expr): Expr {
        val ret = Expr(mark, Expr.Kind.setvar)
        ret.var_ = var_
        ret.arg = arg
        ret.type = var_.type
        ret
    }

    def binop(self, mark: Mark, type: Int, lhs: Expr, rhs: Expr): Expr {
        addType(lhs)
        addType(rhs)
        if type == '=' {
            return when lhs.kind {
                case getvar = setvar(mark, lhs.var_, rhs)
                else = throw MError("" + lhs.kind + " is not assignable", [mark])
            }
        }
        if lhs.type.isInt() and rhs.type.isInt() {
            switch type {
                case '+'           { return genBinop(mark, Expr.Kind.intAdd, Type.int, lhs, rhs) }
                case '-'           { return genBinop(mark, Expr.Kind.intSub, Type.int, lhs, rhs) }
                case '*'           { return genBinop(mark, Expr.Kind.intMul, Type.int, lhs, rhs) }
                case '/'           { return genBinop(mark, Expr.Kind.intDiv, Type.int, lhs, rhs) }
                case '%'           { return genBinop(mark, Expr.Kind.intRem, Type.int, lhs, rhs) }
                case C2Token.tEQ   { return genBinop(mark, Expr.Kind.intEq, Type.int, lhs, rhs) }
                case C2Token.tNE   { return genBinop(mark, Expr.Kind.intNe, Type.int, lhs, rhs) }
                case '<'           { return genBinop(mark, Expr.Kind.intLt, Type.int, lhs, rhs) }
                case C2Token.tLE   { return genBinop(mark, Expr.Kind.intLe, Type.int, lhs, rhs) }
                case '>'           { return genBinop(mark, Expr.Kind.intLt, Type.int, rhs, lhs) }
                case C2Token.tGE   { return genBinop(mark, Expr.Kind.intLe, Type.int, rhs, lhs) }
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
