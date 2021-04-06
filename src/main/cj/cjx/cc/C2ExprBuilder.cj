package cjx.cc

import cj.BigInt
import cj.Uint8Array
import cjx.cc.C2Token
import cjx.parser.MError
import cjx.cc.C2IR.Expr
import cjx.cc.C2IR.Stmt
import cjx.cc.C2IR.Var
import cjx.cc.C2IR.GVar
import cjx.cc.C2IR.Type
import cjx.cc.C2IR.Func
import cjx.parser.Mark

class C2ExprBuilder {

    static val usualArithmeticConversionBinops: Set[Int] = SetOf(
        '*', '/', '%', '+', '-', '<', '>', C2Token.tLE, C2Token.tGE, C2Token.tEQ, C2Token.tNE,
        '&', '^', '|')

    static val usualArithmeticConversionUnops: Set[Int] = SetOf('+', '-', '~')

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

    def block(self, mark: Mark, vars: List[Var], stmts: List[Stmt]): Stmt {
        val newStmts: List[Stmt] = []
        for stmt in stmts {
            if stmt.labels {
                newStmts.add(stmt)
            } else {
                when stmt.kind {
                    case block {
                        if stmt.vars { newStmts.add(stmt) } else { newStmts.addAll(stmt.stmts) }
                    }
                    case nop = ()
                    else = newStmts.add(stmt)
                }
            }
        }
        if vars.isEmpty() and newStmts.size() == 0 {
            nop(mark)
        } else if vars.isEmpty() and newStmts.size() == 1 {
            newStmts[0]
        } else {
            val ret = Stmt(mark, Stmt.Kind.block)
            ret.vars = vars
            ret.stmts = newStmts
            ret
        }
    }

    def if_(self, mark: Mark, cond: Expr, then: Stmt, els: Stmt): Stmt {
        val ret = Stmt(mark, Stmt.Kind.if_)
        ret.cond = castTruthy(cond)
        ret.then = then
        ret.els = els
        ret
    }

    def for_(
            self,
            mark: Mark,
            vars: List[Var],
            inits: List[Stmt],
            cond: Expr,
            incr: Expr,
            then: Stmt): Stmt {
        block(mark, vars, inits + [
            whileEx(mark, cond, incr, then, true),
        ])
    }

    def while_(self, mark: Mark, cond: Expr, then: Stmt): Stmt {
        whileEx(mark, cond, int(mark, 0), then, true)
    }

    ## A version of while expression that has been extended with a for-loop
    ## style 'increment' expression.
    def whileEx(self, mark: Mark, cond: Expr, incr: Expr, then: Stmt, handleContinue: Bool): Stmt {
        val ret = Stmt(mark, Stmt.Kind.whileEx)
        ret.cond = castTruthy(cond)
        ret.incr = incr
        ret.then = then
        ret.handleContinue = handleContinue
        ret
    }

    def break_(self, mark: Mark): Stmt = Stmt(mark, Stmt.Kind.break_)
    def continue_(self, mark: Mark): Stmt = Stmt(mark, Stmt.Kind.continue_)

    ## Only forward goto jumps are supported, as these are the easiest to implement
    ## for a webassembly backend.
    ##
    ## However, by and large, the most useful use cases for gotos I can think of
    ## right now fall into this category. In particular,
    ##   * breaking out of nested loops, and
    ##   * jumping to the end of the function for 'return with cleanup'
    ##
    def goto(self, mark: Mark, label: String): Stmt {
        val ret = Stmt(mark, Stmt.Kind.goto)
        ret.targetLabel = label
        ret
    }

    # ========================================================================
    # Expressions
    # ========================================================================

    ## Implicit cast an expression to a given type
    def icast(self, expr: Expr, type: Type): Expr {
        if val e = icastOrNull(expr, type) { return e }
        throw MError("Expected expression of type " + type + " but got " + expr.type, [expr.mark])
    }

    def _cast(self, expr: Expr, type: Type): Expr {
        val ret = Expr(expr.mark, Expr.Kind.cast)
        ret.arg = expr
        ret.type = type
        ret
    }

    def icastOrNull(self, expr: Expr, type: Type): Expr? {
        addType(expr)
        if expr.type == type {
            return null(expr)
        }

        # integer literals
        if expr.kind == Expr.Kind.int {
            when type {
                case char { return null(char(expr.mark, expr.intValue)) }
                case short { return null(short(expr.mark, expr.intValue)) }
                case long { return null(long(expr.mark, BigInt(expr.intValue))) }
                else = ()
            }
        }

        # widening and narrowing both happen implicitly in C
        if type.isIntegral() and expr.type.isIntegral() {
            return null(_cast(expr, type))
        }

        # For now, we allow any array type to be implicitly converted to any pointer type
        # TODO: check that the conversion is valid
        if type.isPtr() and expr.type.isArray() {
            return null(arrayToPtrEx(expr, type))
        }

        # For now, we allow any ponter type to be implicitly converted to any other
        # pointer type
        # TODO: check that the conversion is valid
        if type.isPtr() and expr.type.isPtr() {
            return null(_cast(expr, type))
        }

        null
    }

    ## Explicit cast
    def ecast(self, expr: Expr, type: Type): Expr {
        if val e = icastOrNull(expr, type) { return e }

        # conversion between integral types and pointers.
        if (type.isIntegral() or type.isPtr()) and (expr.type.isIntegral() or expr.type.isPtr()) {
            return _cast(expr, type)
        }

        # allow anything to be cast to void
        if type.isVoid() {
            return _cast(expr, type)
        }

        throw MError("Could not cast " + expr.type + " to " + type, [expr.mark])
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

    def bool(self, mark: Mark, value: Bool): Expr {
        val ret = Expr(mark, Expr.Kind.bool)
        ret.intValue = Int(value) & 1
        ret.type = Type.bool
        ret
    }

    def short(self, mark: Mark, value: Int): Expr {
        val ret = Expr(mark, Expr.Kind.short)
        ret.intValue = value & 0xFFFF
        ret.type = Type.short
        ret
    }

    def long(self, mark: Mark, value: BigInt): Expr {
        val ret = Expr(mark, Expr.Kind.long)
        ret.bigIntValue = value
        ret.type = Type.long
        ret
    }

    def char(self, mark: Mark, value: Int): Expr {
        val ret = Expr(mark, Expr.Kind.char)
        ret.intValue = value & 0xFF
        ret.type = Type.char
        ret
    }

    def str(self, mark: Mark, value: Uint8Array): Expr {
        val ret = Expr(mark, Expr.Kind.str)
        ret.bytesValue = value
        ret.type = Type.char.arrayOf(value.size() + 1)
        ret
    }

    def stmtExpr(self, mark: Mark, vars: List[Var], stmts: List[Stmt]): Expr {
        val ret = Expr(mark, Expr.Kind.stmt)
        if not stmts or stmts.last().kind != Stmt.Kind.expr {
            throw MError(
                "The last statement of a block expression must be an expression statement",
                [mark])
        }
        val lastStmt = stmts.pop()
        val arg = lastStmt.expr
        if lastStmt.labels {
            val newLast = nop(lastStmt.mark)
            newLast.labels = lastStmt.labels
            stmts.add(newLast)
        }
        ret.vars = vars
        ret.stmts = stmts
        ret.arg = arg
        ret.type = ret.arg.type
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
            case getgvar = addrgvar(mark, expr.gvar)
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
                val func = fexpr.func
                val params = func.params
                if params.size() != args.size() {
                    throw MError(
                        func.name + " expects " + params.size() + " args but got " + args.size(),
                        [mark])
                }
                for i = 0; i < args.size(); i++ {
                    args[i] = icast(args[i], params[i].type)
                }
                val ret = Expr(mark, Expr.Kind.funcall)
                ret.func = func
                ret.args = args
                ret.type = func.type.returnType
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
        ret.arg = icast(arg, var_.type)
        ret.type = var_.type
        ret
    }

    def addrgvar(self, mark: Mark, gvar: GVar): Expr {
        val ret = Expr(mark, Expr.Kind.addrgvar)
        ret.gvar = gvar
        ret.type = Type.ptrOf(gvar.type)
        ret
    }

    def getgvar(self, mark: Mark, gvar: GVar): Expr {
        val ret = Expr(mark, Expr.Kind.getgvar)
        ret.gvar = gvar
        ret.type = gvar.type
        ret
    }

    def setgvar(self, mark: Mark, gvar: GVar, arg: Expr): Expr {
        val ret = Expr(mark, Expr.Kind.setgvar)
        ret.gvar = gvar
        ret.arg = icast(arg, gvar.type)
        ret.type = gvar.type
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

    def initzero(self, mark: Mark, var_: Var): Expr {
        val ret = Expr(mark, Expr.Kind.initzero)
        ret.type = Type.int
        ret.var_ = var_
        ret
    }

    def comma(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        addType(lhs)
        addType(rhs)
        genBinop(mark, Expr.Kind.comma, rhs.type, lhs, rhs)
    }

    @variadic def commaSeq(self, mark: Mark, args: List[Expr]): Expr {
        var ret = args[0]
        for i = 1; i < args.size(); i++ {
            ret = comma(mark, ret, args[i])
        }
        ret
    }

    def getmember(self, mark: Mark, arg: Expr, name: String): Expr {
        addType(arg)
        val derived = when arg.type {
            case derived(s) = s
            else = throw MError("" + arg.type + " is not a struct or union", [mark])
        }
        if not derived.isComplete() {
            throw MError(derived.tag.get() + " is an incomplete type", [mark])
        }
        val member = if val m = derived.getMemberOrNull(name) { m } else {
            throw MError("Member " + name + " not found in " + arg.type, [mark])
        }
        val ret = Expr(mark, Expr.Kind.getmember)
        ret.arg = arg
        ret.member = member
        ret.type = member.type
        ret
    }

    def setmember0(
            self,
            mark: Mark,
            lhs: Expr,
            member: Type.Derived.Member,
            var rhs: Expr): Expr {
        addType(lhs)
        rhs = icast(rhs, member.type)
        val ret = Expr(mark, Expr.Kind.setmember)
        ret.lhs = lhs
        ret.rhs = rhs
        ret.member = member
        ret.type = member.type
        ret
    }

    def assign(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        return when lhs.kind {
            case getvar = setvar(mark, lhs.var_, rhs)
            case getgvar = setgvar(mark, lhs.gvar, rhs)
            case deref = setderef(mark, lhs, icast(rhs, lhs.type))
            case comma = comma(mark, lhs.lhs, binop(mark, '=', lhs.rhs, rhs))
            case getmember = setmember0(mark, lhs.arg, lhs.member, rhs)
            else = throw MError("" + lhs.kind + " is not assignable", [mark])
        }
    }

    ## https://wiki.sei.cmu.edu/confluence/display/c/INT02-C.+Understand+integer+conversion+rules
    def integerPromotion(self, expr: Expr): Expr {
        if expr.type.isIntegral() and expr.type.size() < Type.int.size() {
            icast(expr, Type.int)
        } else { expr }
    }

    ## Determine common real type
    def commonType(self, lhs: Type, rhs: Type): Type {
        if lhs == rhs {
            lhs
        } else if lhs.isSigned() == rhs.isSigned() {
            if lhs.rank() < rhs.rank() { rhs } else { lhs }
        } else {
            throw MError("Could not determine commont type (" + lhs + ", " + rhs + ")", [])
        }
    }

    ## https://en.cppreference.com/w/c/language/conversion
    def usualArithmeticConversion(self, var lhs: Expr, var rhs: Expr): Tuple[Expr, Expr] {
        if lhs.type.isIntegral() and rhs.type.isIntegral() {
            lhs = integerPromotion(lhs)
            rhs = integerPromotion(rhs)
            val type = commonType(lhs.type, rhs.type)
            (icast(lhs, type), icast(rhs, type))
        } else {
            (lhs, rhs)
        }
    }

    def cond(self, mark: Mark, cond: Expr, var lhs: Expr, var rhs: Expr): Expr {
        addType(cond)
        addType(lhs)
        addType(rhs)

        val (newLhs, newRhs) = usualArithmeticConversion(lhs, rhs)
        lhs = newLhs
        rhs = newRhs

        val ret = Expr(mark, Expr.Kind.cond)
        ret.arg = truthy(cond)
        ret.lhs = lhs
        ret.rhs = rhs
        ret.type = lhs.type

        ret
    }

    def truthy(self, expr: Expr): Expr {
        binop(expr.mark, C2Token.tNE, expr, int(expr.mark, 0))
    }

    def binop(self, mark: Mark, type: Int, var lhs: Expr, var rhs: Expr): Expr {
        addType(lhs)
        addType(rhs)

        if type in usualArithmeticConversionBinops {
            val (newLhs, newRhs) = usualArithmeticConversion(lhs, rhs)
            lhs = newLhs
            rhs = newRhs
        }

        switch type {
            case C2Token.tSHL
            case C2Token.tSHR {
                lhs = integerPromotion(lhs)
                rhs = integerPromotion(rhs)
            }
            else = ()
        }

        # ======================================================================
        # logical
        # ======================================================================
        switch type {
            case C2Token.tOR
            case C2Token.tAND {
                val op = switch type {
                    case C2Token.tAND = Expr.Kind.logicalAnd
                    case C2Token.tOR = Expr.Kind.logicalOr
                }
                return genBinop(mark, op, Type.int, truthy(lhs), truthy(rhs))
            }
            else = ()
        }

        # ======================================================================
        # comma
        # ======================================================================
        switch type {
            case ',' { return comma(mark, lhs, rhs) }
            case '=' { return assign(mark, lhs, rhs) }
            else = ()
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
                case '&' { return genBinop(mark, Expr.Kind.intBitwiseAnd, Type.int, lhs, rhs) }
                case '|' { return genBinop(mark, Expr.Kind.intBitwiseOr, Type.int, lhs, rhs) }
                case '^' { return genBinop(mark, Expr.Kind.intBitwiseXor, Type.int, lhs, rhs) }
                case C2Token.tSHL  { return genBinop(mark, Expr.Kind.intShl, Type.int, lhs, rhs) }
                case C2Token.tSHR  { return genBinop(mark, Expr.Kind.intShr, Type.int, lhs, rhs) }
                else = ()
            }
        }
        if lhs.type.isLong() and rhs.type.isLong() {
            switch type {
                case '+'           { return genBinop(mark, Expr.Kind.longAdd, Type.long, lhs, rhs) }
                case '-'           { return genBinop(mark, Expr.Kind.longSub, Type.long, lhs, rhs) }
                case '*'           { return genBinop(mark, Expr.Kind.longMul, Type.long, lhs, rhs) }
                case '/'           { return genBinop(mark, Expr.Kind.longDiv, Type.long, lhs, rhs) }
                case '%'           { return genBinop(mark, Expr.Kind.longRem, Type.long, lhs, rhs) }
                case C2Token.tEQ   { return genBinop(mark, Expr.Kind.longEq, Type.int, lhs, rhs) }
                case C2Token.tNE   { return genBinop(mark, Expr.Kind.longNe, Type.int, lhs, rhs) }
                case '<'           { return genBinop(mark, Expr.Kind.longLt, Type.int, lhs, rhs) }
                case C2Token.tLE   { return genBinop(mark, Expr.Kind.longLe, Type.int, lhs, rhs) }
                case '>'           { return genBinop(mark, Expr.Kind.longLt, Type.int, rhs, lhs) }
                case C2Token.tGE   { return genBinop(mark, Expr.Kind.longLe, Type.int, rhs, lhs) }
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

    def preop(self, mark: Mark, type: Int, var arg: Expr): Expr {
        addType(arg)

        if type in usualArithmeticConversionUnops {
            arg = integerPromotion(arg)
        }

        switch type {
            case '&' { return addr(mark, arg) }
            case '*' { return deref(mark, arg) }
            case '!' { return genUnop(mark, Expr.Kind.logicalNot, Type.int, ecast(arg, Type.int)) }
            case '~' {
                return genUnop(mark, Expr.Kind.intBitwiseNot, Type.int, icast(arg, Type.int))
            }
            else = ()
        }
        if arg.type.isIntegral() and arg.type.rank() <= Type.int.rank() {
            arg = integerPromotion(arg)
            switch type {
                case '-' {
                    return when arg.kind {
                        case int = int(mark, -arg.intValue)
                        else = genUnop(mark, Expr.Kind.intNeg, Type.int, arg)
                    }
                }
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
