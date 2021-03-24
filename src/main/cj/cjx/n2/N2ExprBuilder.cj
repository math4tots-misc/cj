package cjx.n2

import cjx.parser.Mark
import cjx.n2.N2Error
import cjx.n2.N2Locals
import cjx.n2.N2IR.Program
import cjx.n2.N2IR.Type
import cjx.n2.N2IR.Var
import cjx.n2.N2IR.Expr
import cjx.n2.N2IR.Func
import cjx.n2.N2IR.FuncTemplate
import cjx.n2.N2IR.Struct
import cjx.n2.N2IR.StructTemplate
import cjx.n2.N2IR.Trait
import cjx.n2.N2IR.TPat

class N2ExprBuilder {
    val program: Program

    def int(self, mark: Mark, value: Int): Expr {
        val ret = Expr(mark, Expr.kINT, Type.int)
        ret.intValue = value
        ret
    }

    def str(self, mark: Mark, value: String): Expr {
        val ret = Expr(mark, Expr.kSTR, Type.str)
        ret.stringValue = value
        ret
    }

    def getvar(self, mark: Mark, var_: Var): Expr {
        val ret = Expr(mark, Expr.kGETVAR, var_.type)
        ret.var_ = var_
        ret
    }

    def setvar(self, mark: Mark, var_: Var, valexpr: Expr): Expr {
        val ret = unop(mark, Expr.kSETVAR, var_.type, icast(valexpr, var_.type))
        ret.var_ = var_
        ret
    }

    def declvar(self, mark: Mark, var_: Var): Expr {
        val expr = Expr(mark, Expr.kDECLVAR, Type.void)
        if val init = var_.init {
            var_.init = null(icast(init, var_.type))
        }
        expr.var_ = var_
        expr
    }

    def getfunc(self, mark: Mark, func: Func, refName: String): Expr {
        val ret = Expr(mark, Expr.kGETFUNC, func.type)
        ret.func = func
        ret.refName = refName
        ret
    }

    def getfuncTemplate(self, mark: Mark, funcTemplate: FuncTemplate, refName: String): Expr {
        val ret = Expr(mark, Expr.kGETFUNCTEMP, Type.meta)
        ret.funcTemplate = funcTemplate
        ret.refName = refName
        ret
    }

    def boundfunc(self, mark: Mark, func: Func, expr: Expr, refName: String): Expr {
        val ret = unop(mark, Expr.kBOUNDFUNC, Type.meta, expr)
        ret.func = func
        ret.refName = refName
        ret
    }

    def boundfuncTemplate(self, mark: Mark, ft: FuncTemplate, expr: Expr, refName: String): Expr {
        val ret = unop(mark, Expr.kBOUNDFUNCTEMP, Type.meta, expr)
        ret.funcTemplate = ft
        ret.refName = refName
        ret
    }

    def getstructTemplate(self, mark: Mark, structTemplate: StructTemplate): Expr {
        val ret = Expr(mark, Expr.kGETSTRUCTTEMP, Type.meta)
        ret.structTemplate = structTemplate
        ret
    }

    def callf(self, mark: Mark, func: Func, args: List[Expr]): Expr {
        val ret = Expr(mark, Expr.kCALL, func.returnType)
        ret.func = func
        ret.args = args
        if args.size() != func.nparams {
            throw N2Error(
                "Expected " + func.params.size() + " args but got " + args.size(), [mark])
        }
        val params = func.params
        for i = 0; i < args.size(); i++ {
            args[i] = icast(args[i], params[i].type)
        }
        ret
    }

    def newstruct(self, mark: Mark, struct_: Struct, args: List[Expr]): Expr {
        val ret = Expr(mark, Expr.kNEWSTRUCT, Type.struct_(struct_))
        ret.struct_ = struct_
        ret.args = args
        ret
    }

    def getfield(self, mark: Mark, owner: Expr, struct_: Struct, field: Var): Expr {
        val ret = unop(mark, Expr.kGETFIELD, field.type, owner)
        ret.var_ = field
        ret.struct_ = struct_
        ret
    }

    def js(self, mark: Mark, type: Type, args: List[Expr]): Expr {
        val ret = Expr(mark, Expr.kJS, type)
        ret.args = args
        ret
    }

    def evalType(self, expr: Expr): Type {
        switch expr.kind {
            case Expr.kTYPE { return expr.ty }
            case Expr.kGETFUNC; case Expr.kGETFUNCTEMP;
            case Expr.kBOUNDFUNC; case Expr.kBOUNDFUNCTEMP {
                if val type = program.getTypeOrNull(expr.refName) {
                    return type
                }
            }
            else = ()
        }
        throw N2Error("Expected type but got " + expr, [expr.mark])
    }

    def evalNumericType(self, expr: Expr): Type {
        val type = evalType(expr)
        when type {
            case int = type
            else {
                throw N2Error("Expected numeric type but got " + type, [expr.mark])
            }
        }
    }

    def checkMinArgc(self, mark: Mark, args: List[Expr], argc: Int) {
        if args.size() < argc {
            throw N2Error(
                "Expected at least " + argc + " args but got " + args.size(), [mark])
        }
    }

    def checkArgc(self, mark: Mark, args: List[Expr], argc: Int) {
        if args.size() != argc {
            throw N2Error(
                "Expected " + argc + " args but got " + args.size(), [mark])
        }
    }

    def macro(self, mark: Mark, program: Program, macroName: String, args: List[Expr]): Expr {
        switch macroName {
            case "js!" {
                checkMinArgc(mark, args, 2)
                js(mark, evalType(args[0]), args[1:])
            }
            else = throw N2Error("Unrecognized macro '" + macroName + "'", [mark])
        }
    }

    def assign(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.kind == Expr.kGETVAR {
            return setvar(mark, lhs.var_, rhs)
        }
        throw N2Error(lhs.kindName + " is not assignable", [mark])
    }

    def type(self, mark: Mark, type: Type): Expr {
        val ret = Expr(mark, Expr.kTYPE, Type.meta)
        ret.ty = type
        ret
    }

    def nullwrap(self, mark: Mark, expr: Expr): Expr {
        if tag!(expr.type) == tag!(Type, null_) {
            throw N2Error("null type cannot be nested", [mark])
        }
        if tag!(expr.type) == tag!(Type, meta) {
            throw N2Error("a concretely typed value is expected here", [mark])
        }
        val type = Type.null_(expr.type)
        unop(mark, Expr.kNULLWRAP, type, expr)
    }

    def nullexpr(self, mark: Mark): Expr {
        Expr(mark, Expr.kNULL, Type.meta)
    }

    def typednull(self, mark: Mark, type: Type): Expr {
        Expr(mark, Expr.kNULL, type)
    }

    def if_(self, mark: Mark, var cond: Expr, then: Expr, els: Expr): Expr {
        val type = Type.common(mark, then.type, els.type)
        val ret = Expr(mark, Expr.kIF, type)
        ret.cond = icast(cond, Type.bool)
        ret.then = icast(then, type)
        ret.els = icast(els, type)
        ret
    }

    def while_(self, mark: Mark, cond: Expr, then: Expr): Expr {
        val ret = Expr(mark, Expr.kWHILE, Type.void)
        ret.cond = icast(cond, Type.int)
        ret.then = then
        ret
    }

    def list(self, mark: Mark, var args: List[Expr], itemType: Type?): Expr {
        if not args and itemType.isEmpty() {
            val ret = Expr(mark, Expr.kARRAY, Type.meta)
            ret.args = []
            ret
        } else {
            val itype = if val t = itemType { t } else { args[0].type }
            args = args.map(a -> icast(a, itype))
            val ret = Expr(mark, Expr.kARRAY, Type.list(itype))
            ret.args = args
            ret
        }
    }

    def getitem(self, mark: Mark, owner: Expr, index: Expr): Expr {
        when owner.type {
            case list(itemType) {
                val ret = Expr(mark, Expr.kARRAY_GET, itemType)
                ret.lhs = owner
                ret.rhs = index
                ret
            }
            else = throw N2Error("Subscripting not supported for " + owner.type, [mark])
        }
    }
    ## implicit cast
    def icast(self, var expr: Expr, type: Type): Expr {
        if type.isBool() and expr.type.isInt() {
            expr = unop(expr.mark, Expr.kINT_TO_BOOL, Type.bool, expr)
        }
        if type.isNull() and expr.kind == Expr.kNULL and expr.type.isMeta() {
            return typednull(expr.mark, type)
        }
        if type.isArray() and expr.kind == Expr.kARRAY and expr.type.isMeta() {
            Assert.that(expr.args.isEmpty())
            return icast(list(expr.mark, expr.args, null(type.itemType)), type)
        }
        if expr.type.isMeta() {
            throw N2Error("Expected expression, but got type", [expr.mark])
        }
        if expr.type == type or expr.type.isUnreachable() { # no cast needed
            return expr
        }
        if type.isVoid() { # cast to void
            return block(expr.mark, [expr, nop(expr.mark)])
        }
        if type.isVar() and not expr.type.isVoid() {
            return expr
        }
        if type.isNull() and not expr.type.isNull() {
            return icast(nullwrap(expr.mark, expr), type)
        }
        throw N2Error("Expected " + type + " but got " + expr.type, [expr.mark])
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

    def neg(self, mark: Mark, arg: Expr): Expr {
        if arg.type.isInt() {
            if arg.kind == Expr.kINT {
                return int(mark, -arg.intValue)
            } else {
                return unop(mark, Expr.kINT_NEG, Type.int, arg)
            }
        }
        throw N2Error(
            "Invalid args to unary '-' (" + arg.type + ")", [mark])
    }

    def pos(self, mark: Mark, arg: Expr): Expr {
        if arg.type.isInt() {
            return arg
        }
        throw N2Error(
            "Invalid args to unary '-' (" + arg.type + ")", [mark])
    }

    def incr(self, mark: Mark, expr: Expr): Expr {
        if not expr.type.isInt() {
            throw N2Error("Only int types can be incremented but got " + expr.type, [mark])
        }
        switch expr.kind {
            case Expr.kGETVAR {
                val ret = Expr(mark, Expr.kINTVAR_INCR, Type.int)
                ret.var_ = expr.var_
                return ret
            }
        }
        throw N2Error(expr.kindName + " expressions cannot be incremented", [mark])
    }

    def decr(self, mark: Mark, expr: Expr): Expr {
        if not expr.type.isInt() {
            throw N2Error("Only int types can be decremented but got " + expr.type, [mark])
        }
        switch expr.kind {
            case Expr.kGETVAR {
                val ret = Expr(mark, Expr.kINTVAR_DECR, Type.int)
                ret.var_ = expr.var_
                return ret
            }
        }
        throw N2Error(expr.kindName + " expressions cannot be decremented", [mark])
    }

    def add(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_ADD, Type.int, lhs, rhs)
        } else if lhs.type.isStr() and rhs.type.isStr() {
            return binop(mark, Expr.kSTR_ADD, Type.str, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '+' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def sub(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_SUB, Type.int, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '-' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def mul(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_MUL, Type.int, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '*' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def div(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_DIV, Type.int, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '/' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def rem(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_REM, Type.int, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '%' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def eq(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_EQ, Type.int, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '==' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def ne(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_NE, Type.int, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '!=' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def lt(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_LT, Type.int, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '<' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def le(self, mark: Mark, lhs: Expr, rhs: Expr): Expr {
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Expr.kINT_LE, Type.int, lhs, rhs)
        }
        throw N2Error(
            "Invalid args to binary '<=' (" + lhs.type + "," + rhs.type + ")", [mark])
    }

    def and_(self, mark: Mark, var lhs: Expr, var rhs: Expr): Expr {
        lhs = icast(lhs, Type.bool)
        rhs = icast(rhs, Type.bool)
        return binop(mark, Expr.kLOGICAL_AND, Type.bool, lhs, rhs)
    }

    def or_(self, mark: Mark, var lhs: Expr, var rhs: Expr): Expr {
        lhs = icast(lhs, Type.bool)
        rhs = icast(rhs, Type.bool)
        return binop(mark, Expr.kLOGICAL_OR, Type.bool, lhs, rhs)
    }

    def ret(self, mark: Mark, expr: Expr): Expr {
        return unop(mark, Expr.kRETURN, Type.unreachable, expr)
    }

    def block(self, mark: Mark, stmts: List[Expr]): Expr {
        val type = if stmts { stmts.last().type } else { Type.void }
        val block = Expr(mark, Expr.kBLOCK, type)
        block.stmts = stmts
        block.newScope = true
        block
    }

    def seq(self, mark: Mark, stmts: List[Expr]): Expr {
        if stmts.size() == 1 {
            return stmts[0]
        }
        val type = if stmts { stmts.last().type } else { Type.void }
        val block = Expr(mark, Expr.kBLOCK, type)
        block.stmts = stmts
        block.newScope = false
        block
    }

    def nop(self, mark: Mark): Expr = seq(mark, [])
}
