package cjx.cc

import cjx.cc.C2Token
import cjx.parser.MError
import cjx.cc.C2IR.Expr
import cjx.cc.C2IR.Stmt
import cjx.cc.C2IR.Var
import cjx.cc.C2IR.Type
import cjx.cc.C2IR.Func
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
        if expr.type == type {
            return expr
        }
        if type.isPtr() and expr.type.isArray() {
            # Arrays may decay to pointers
            # TODO: check that this conversion is valid
            return arrayToPtrEx(expr, type)
        }
        if expr.type.intPtrConvertible() and type.intPtrConvertible() {
            # TODO: Consider warning... for now, just allow
            return expr
        }
        throw MError("Expected " + type + " but got " + expr.type, [expr.mark])
    }

    ## Decay an array to a pointer
    def arrayToPtr(self, arrExpr: Expr): Expr {
        val ret = genUnop(
            arrExpr.mark, Expr.Kind.arrayToPtr, arrExpr.type.base.ptrOf(), arrExpr)
        ret
    }

    ## Decay an array to an arbitrary pointer
    def arrayToPtrEx(self, arrExpr: Expr, ptrType: Type): Expr {
        val ret = genUnop(
            arrExpr.mark, Expr.Kind.arrayToPtr, ptrType, arrExpr)
        ret
    }

    ## Implicitly cast the given expression to some sort of pointer
    def icastptr(self, expr: Expr): Expr {
        addType(expr)
        when expr.type {
            case ptr(..) = expr
            case array(..) = arrayToPtr(expr)
            else = throw MError(
                "Expected a pointer but got " + expr.type, [expr.mark])
        }
    }

    def icastvalptr(self, var expr: Expr): Expr {
        expr = icastptr(expr)
        if expr.type.base.isVoid() {
            throw MError("Expected a non-void pointer but got " + expr.type, [expr.mark])
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

    def char(self, mark: Mark, value: Int): Expr {
        val ret = Expr(mark, Expr.Kind.char)
        ret.intValue = value
        ret.type = Type.char
        ret
    }

    def deref(self, mark: Mark, var expr: Expr): Expr {
        expr = icastvalptr(expr)
        val ret = Expr(mark, Expr.Kind.deref)
        ret.type = expr.type.base
        ret.arg = expr
        ret
    }

    def addr(self, mark: Mark, expr: Expr): Expr {
        when expr.kind {
            case getvar = addrvar(mark, expr.var_)
            case deref = expr.arg
            else = throw MError("" + expr.kind + " is not an l-value", [expr.mark])
        }
    }

    def func(self, mark: Mark, func: Func): Expr {
        val ret = Expr(mark, Expr.Kind.func)
        ret.func = func
        ret.type = Type.func(func.type)
        ret
    }

    def call(self, mark: Mark, fexpr: Expr, args: List[Expr]): Expr {
        when fexpr.kind {
            case func {
                val ret = Expr(mark, Expr.Kind.funcall)
                ret.func = fexpr.func
                ret.args = args
                ret.type = fexpr.func.type.returnType
                ret
            }
            else = throw MError("" + fexpr.type + " is not callable", [mark])
        }
    }

    def addrvar(self, mark: Mark, var_: Var): Expr {
        val ret = Expr(mark, Expr.Kind.addrvar)
        ret.var_ = var_
        ret.type = Type.ptrOf(var_.type)
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

    def setderef(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        Assert(lhs.kind == Expr.Kind.deref)
        val ret = Expr(mark, Expr.Kind.setderef)
        ret.type = rhs.type
        ret.lhs = lhs.arg
        ret.rhs = rhs
        ret
    }

    def binop(self, mark: Mark, type: Int, var lhs: Expr, var rhs: Expr): Expr {
        addType(lhs)
        addType(rhs)

        # ======================================================================
        # assignment
        # ======================================================================
        if type == '=' {
            return when lhs.kind {
                case getvar = setvar(mark, lhs.var_, icast(rhs, lhs.type))
                case deref = setderef(mark, lhs, icast(rhs, lhs.type))
                else = throw MError("" + lhs.kind + " is not assignable", [mark])
            }
        }

        # ======================================================================
        # arithmetic
        # ======================================================================
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

        # ======================================================================
        # pointer ops
        # ======================================================================
        if type == '+' and lhs.type.isInt() and rhs.type.isPtrOrArray() {
            # transform int + ptr to ptr + int
            val tmp = rhs
            rhs = lhs
            lhs = tmp
        }
        if lhs.type.isPtrOrArray() and rhs.type.isInt() {
            switch type {
                case '+' {
                    lhs = icastptr(lhs)
                    return genBinop(mark, Expr.Kind.ptrAdd, lhs.type, lhs, rhs)
                }
                case '-' {
                    lhs = icastptr(lhs)
                    return genBinop(mark, Expr.Kind.ptrSub, lhs.type, lhs, rhs)
                }
                else = ()
            }
        }
        if lhs.type.isPtrOrArray() and rhs.type.isPtrOrArray() and lhs.type.base == rhs.type.base {
            switch type {
                case '-' {
                    lhs = icastptr(lhs)
                    rhs = icastptr(rhs)
                    return genBinop(mark, Expr.Kind.ptrDiff, Type.int, lhs, rhs)
                }
                else = ()
            }
        }

        throw MError(
            "TODO eb.binop " + C2Token.typeRepr(type) + "(" + lhs.type + ", " + rhs.type + ")",
            [mark])
    }

    def preop(self, mark: Mark, type: Int, arg: Expr): Expr {
        addType(arg)
        switch type {
            case '&' { return addr(mark, arg) }
            case '*' { return deref(mark, arg) }
            else = ()
        }
        if arg.type.isInt() {
            switch type {
                case '-' { return genUnop(mark, Expr.Kind.intNeg, Type.int, arg) }
                case '+' { return arg }
                else = ()
            }
        }
        throw MError("TODO eb.preop " + C2Token.typeRepr(type), [mark])
    }

    def postop(self, mark: Mark, type: Int, arg: Expr): Expr {
        addType(arg)
        if type == C2Token.tINCR {
            when arg.type {
                case int; case ptr(..) = return genUnop(
                    mark, Expr.Kind.postIncr, arg.type, addr(mark, arg))
                else = ()
            }
        }
        if type == C2Token.tDECR {
            when arg.type {
                case int; case ptr(..) = return genUnop(
                    mark, Expr.Kind.postDecr, arg.type, addr(mark, arg))
                else = ()
            }
        }
        throw MError("TODO eb.postop " + C2Token.typeRepr(type) + " (" + arg.type + ")", [mark])
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
