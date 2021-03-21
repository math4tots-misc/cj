package cjx.notc

import cj.Error
import cjx.notc.NCError
import cjx.parser.Mark

class NCIR {
    static val ptrSize = 4

    class Program {
        val funcs: List[Func] = []
        val funcMap: Map[String, Func] = MapOf()
        val constMap: Map[String, Int] = MapOf()

        def addFunc(self, func: Func) {
            funcs.add(func)
            funcMap[func.name] = func
        }

        def getFuncOrNull(self, funcName: String): Func? {
            funcMap.getOrNull(funcName)
        }

        def addConst(self, name: String, value: Int) {
            constMap[name] = value
        }

        def getConstOrNull(self, name: String): Int? = constMap.getOrNull(name)
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
        def __get_type(self): Type = Type.func(returnType, params.map(p -> p.type))
    }

    union Type: Repr, Eq {
        case unreachable
        case void
        case int
        case type
        case array(Type)
        case func(Type, List[Type])
        def isUnreachable(self): Bool = tag!(self) == tag!(Type, unreachable)
        def isVoid(self): Bool = tag!(self) == tag!(Type, void)
        def isInt(self): Bool = tag!(self) == tag!(Type, int)
        def isMeta(self): Bool = tag!(self) == tag!(Type, type)
        def isArray(self): Bool = tag!(self) == tag!(Type, array)
        def isFunc(self): Bool = tag!(self) == tag!(Type, func)
        def size(self): Int = when self {
            case unreachable = 0
            case void = NCIR.ptrSize
            case int = NCIR.ptrSize
            case type = NCIR.ptrSize
            case array(..) = NCIR.ptrSize
            case func(..) = throw Error("Func type not supported here")
        }
        def repr(self): String = when self {
            case array(t) = "array(" + t + ")"
            else = tag_name!(self)
        }
        def __eq(self, other: Self): Bool = tag!(self) == tag!(other) and switch tag!(self) {
            case tag!(Self, func) = when self {
                case func(rt, argts) = when other {
                    case func(ort, oargts) = rt == ort and argts == oargts
                    else = false
                }
                else = throw Error("FUBAR")
            }
            else = true
        }
        def __get_itemType(self): Type = get!(self, array, 0)
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
            kINT_REM
            kINT_NEG
            kINT_EQ
            kINT_NE
            kINT_LT
            kINT_LE

            kGETVAR
            kSETVAR

            kARRAY
            kGETITEM
            kSETITEM

            kNEWARRAY

            kIF
            kWHILE

            kGETFUNC
            kCALL

            kRETURN

            kBLOCK

            kTYPE

            # low-level operations
            kMEMSIZE
            kLOAD
            kSTORE
        }

        private static val kindNames: List[String] = static_field_names!(Self, "k[A-Z_]+")

        val mark: Mark
        val kind: Int
        var type: Type

        # literals
        var intValue: Int = ?

        # variable
        var var_: Var = ?

        # binops/unops/getitem/setitem
        var lhs: Expr = ?
        var rhs: Expr = ?
        var arg: Expr = ?

        # if/while
        var cond: Expr = ?
        var then: Expr = ?
        var els: Expr = ?

        # getfunc/call/array
        var func: Func = ?
        def __get_args(self): List[Expr] = stmts
        def __set_args(self, value: List[Expr]) { stmts = value }

        # type/meta
        var ty: Type = ?

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
            val self = unop(mark, kSETVAR, var_.type, icast(valexpr, var_.type))
            self.var_ = var_
            self
        }

        def getfunc(mark: Mark, func: Func): Self {
            val self = Self(mark, kGETFUNC, func.type)
            self.func = func
            self
        }

        def call(mark: Mark, fexpr: Expr, args: List[Expr]): Self {
            if fexpr.kind == kGETFUNC {
                val self = Self(mark, kCALL, fexpr.func.returnType)
                self.func = fexpr.func
                self.args = args
                return self
            }
            throw NCError(kindNames[fexpr.kind] + " is not callable", [mark])
        }

        def evalType(expr: Expr): Type {
            if expr.kind != kTYPE {
                throw NCError("Expected type", [expr.mark])
            }
            expr.ty
        }

        def evalNumericType(expr: Expr): Type {
            val type = evalType(expr)
            when type {
                case int = type
                else {
                    throw NCError("Expected numeric type but got " + type, [expr.mark])
                }
            }
        }

        def memsize(mark: Mark): Self = Self(mark, kMEMSIZE, Type.int)

        def load(mark: Mark, addr: Expr): Self = unop(mark, kLOAD, Type.int, icast(addr, Type.int))

        def store(mark: Mark, addr: Expr, value: Expr): Self {
            binop(mark, kSTORE, Type.void, icast(addr, Type.int), icast(value, Type.int))
        }

        def macro(mark: Mark, macroName: String, args: List[Expr]): Self {
            switch macroName {
                case "new!" = switch args.size() {
                    case 1 = throw NCError("TODO new!(Type)", [mark])
                    case 2 {
                        val itemType = evalType(args[0])
                        unop(mark, kNEWARRAY, Type.array(itemType), args[1])
                    }
                    else = throw NCError("new! requires 1 or 2 args", [mark])
                }
                case "memsize!" = memsize(mark)
                case "load!" {
                    if args.size() != 1 { throw NCError("load! requires 1 arg", [mark]) }
                    load(mark, args[0])
                }
                case "store!" {
                    if args.size() != 2 { throw NCError("store! requires 2 arg", [mark]) }
                    store(mark, args[0], args[1])
                }
                else = throw NCError("Unrecognized macro '" + macroName + "'", [mark])
            }
        }

        def assign(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.kind == kGETVAR {
                return setvar(mark, lhs.var_, rhs)
            }
            throw NCError(kindNames[lhs.kind] + " is not assignable", [mark])
        }

        def type(mark: Mark, type: Type): Self {
            val self = Self(mark, kTYPE, Type.type)
            self.ty = type
            self
        }

        def if_(mark: Mark, cond: Expr, then: Expr, els: Expr): Self {
            if not cond.type.isInt() {
                throw NCError("'if' condition should be an int, but got " + cond.type, [mark])
            }
            val type = Type.common(mark, cond.type, els.type)
            val self = Self(mark, kIF, type)
            self.cond = icast(cond, Type.int)
            self.then = icast(then, type)
            self.els = icast(els, type)
            self
        }

        def while_(mark: Mark, cond: Expr, then: Expr): Self {
            val self = Self(mark, kWHILE, Type.void)
            self.cond = icast(cond, Type.int)
            self.then = then
            self
        }

        def array(mark: Mark, var args: List[Expr], itemType: Type?): Self {
            if not args and itemType.isEmpty() {
                throw NCError("Could not infer type of array", [mark])
            }
            val itype = if val t = itemType { t } else { args[0].type }
            args = args.map(a -> icast(a, itype))
            val self = Self(mark, kARRAY, Type.array(itype))
            self.args = args
            self
        }

        def getitem(mark: Mark, owner: Expr, index: Expr): Expr {
            when owner.type {
                case array(itemType) {
                    val self = Self(mark, kGETITEM, itemType)
                    self.lhs = owner
                    self.rhs = index
                    self
                }
                else = throw NCError("Subscripting not supported for " + owner.type, [mark])
            }
        }

        ## implicit cast
        private def icast(expr: Expr, type: Type): Expr {
            if expr.type.isMeta() {
                throw NCError("Expected expression, but got type", [expr.mark])
            }
            if expr.type == type or expr.type.isUnreachable() { # no cast needed
                return expr
            }
            if type.isVoid() { # cast to void
                return block(expr.mark, [expr, nop(expr.mark)])
            }
            throw NCError("Expected " + type + " but got " + expr.type, [expr.mark])
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

        def rem(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_REM, Type.int, lhs, rhs)
            }
            throw NCError(
                "Invalid args to binary '%' (" + lhs.type + "," + rhs.type + ")", [mark])
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
