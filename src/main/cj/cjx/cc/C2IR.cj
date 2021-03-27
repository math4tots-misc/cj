package cjx.cc

import cj.Uint8Array
import cjx.cc.C2Locals
import cj.StringBuilder
import cj.Error
import cjx.parser.Mark

class C2IR {
    class TranslationUnit {
        val gvars: List[GVar] = []
        val gvarMap: Map[String, GVar] = MapOf()
        val funcs: List[Func] = []
        val funcMap: Map[String, Func] = MapOf()
        def addFunc(self, func: Func) {
            Assert(func.name not in funcMap)
            funcs.add(func)
            funcMap[func.name] = func
        }
        def getFuncOrNull(self, name: String): Func? = funcMap.getOrNull(name)
        def addGVar(self, gvar: GVar) {
            Assert(gvar.name not in gvarMap)
            gvars.add(gvar)
            gvarMap[gvar.name] = gvar
        }
        def getGVarOrNull(self, name: String): GVar? = gvarMap.getOrNull(name)
    }
    @implicit(Type.Func, func)
    union Type: Repr, Eq {
        class Func {
            val returnType: Type
            val params: List[Var]
            def __get_paramTypes(self): List[Type] = params.map(p -> p.type)
            def __eq(self, other: Self): Bool = (
                returnType == other.returnType and paramTypes == other.paramTypes)
        }
        class Ptr {
            val base: Type
            def __eq(self, other: Self): Bool = base == other.base
        }
        class Array {
            val base: Type
            val len: Int
            def __eq(self, other: Self): Bool = base == other.base and len == other.len
        }
        class Struct {
        }
        case void
        case char
        case int
        case ptr(Ptr)
        case array(Array)
        case func(Func)
        case struct_(Struct)
        def isVoid(self): Bool = tag!(self) == tag!(Self, void)
        def isChar(self): Bool = tag!(self) == tag!(Self, char)
        def isInt(self): Bool = tag!(self) == tag!(Self, int)
        def isPtr(self): Bool = tag!(self) == tag!(Self, ptr)
        def isArray(self): Bool = tag!(self) == tag!(Self, array)
        def isFunc(self): Bool = tag!(self) == tag!(Self, func)
        def isPtrOrArray(self): Bool = isPtr() or isArray()
        def intPtrConvertible(self): Bool = when self {
            case void; case char; case int; case ptr(..) = true
            else = false
        }
        def repr(self): String = when self {
            case ptr(p) = "ptr(" + p.base + ")"
            case array(a) = "array(" + a.base + "," + a.len + ")"
            case func(f) = "func(" + f.returnType + "," + f.params + ")"
            case struct_(s) = "struct()"
            else name() = name
        }
        def __eq(self, other: Self): Bool = tag!(self) == tag!(other) and when self {
            case ptr(p) = p == get!(other, ptr, 0)
            case array(a) = a == get!(other, array, 0)
            case func(f) = f == get!(other, func, 0)
            case struct_(s) = throw Error("TODO struct type equality")
            else() = true
        }
        def ptrOf(t: Type): Type = Type.ptr(Ptr(t))
        def arrayOf(t: Type, len: Int): Type = Type.array(Array(t, len))
        def size(self): Int = when self {
            case char = 1
            case void; case int; case ptr(..); case func(..) = 4
            case array(a) = a.len * a.base.size()
            case struct_(..) = IO.panic("TODO Type.size sruct")
        }
        def alignment(self): Int = when self {
            case array(a) = a.base.alignment()
            case struct_(..) = IO.panic("TODO Type.alignment struct")
            case ptr(..); case func(..) = size()
            else() = size()
        }
        def __get_returnType(self): Type = get!(self, func, 0).returnType
        def __get_params(self): List[Var] = get!(self, func, 0).params
        def __get_paramTypes(self): List[Type] = params.map(v -> v.type)
        def __get_base(self): Type = when self {
            case ptr(p) = p.base
            case array(a) = a.base
            else = IO.panic("Type.base " + self)
        }
    }
    class Var: Repr { # local variable
        val mark: Mark
        val name: String
        val type: Type
        val index: Int
        def repr(self): String = "Var(" + name + "," + type + "," + index + ")"
        def toString(self): String = ("" + type + " " + name).trim()
    }
    class GVar: Repr { # global variable
        val mark: Mark
        val name: String
        val type: Type
        def repr(self): String = "GVar(" + name + "," + type + ")"
    }
    class Func {
        val mark: Mark
        val name: String
        val type: Type.Func
        var body: Stmt = ?
        var locals: C2Locals = ?
        def __get_params(self): List[Var] = locals.list[:type.params.size()]
    }
    class Stmt: Repr {
        union Kind: Repr, Hash {
            case nop
            case block
            case expr
            case ret
            case if_
            case while_
            def repr(self): String = tag_name!(self)
            def __eq(self, other: Self): Bool = self is other
            def hash(self): Int = tag!(self)
        }
        val mark: Mark
        val kind: Kind
        var stmts: List[Stmt] = ?
        var expr: Expr = ?
        var cond: Expr = ?
        var then: Stmt = ?
        var els: Stmt = ?

        def repr(self): String {
            val sb = StringBuilder()
            sb.str("{\"kind\":\"" + kind + "\"")
            if is_set!(self, stmts) { sb.str(",\"stmts\":" + stmts.repr()) }
            if is_set!(self, expr) { sb.str(",\"expr\":" + expr.repr()) }
            if is_set!(self, cond) { sb.str(",\"cond\":" + cond.repr()) }
            if is_set!(self, then) { sb.str(",\"then\":" + then.repr()) }
            if is_set!(self, els) { sb.str(",\"els\":" + els.repr()) }
            sb.str("}")
            sb.toString()
        }
    }
    class Expr: Repr {
        union Kind: Repr, Hash {
            case int
            case intNeg
            case intAdd
            case intSub
            case intMul
            case intDiv
            case intRem
            case intEq
            case intNe
            case intLt
            case intLe

            case char
            case charNeg
            case charAdd
            case charSub
            case charMul
            case charDiv
            case charRem
            case charEq
            case charNe
            case charLt
            case charLe

            case str

            case comma

            case postIncr
            case postDecr

            case arrayToPtr  # decay an array to a pointer

            case func        # function reference
            case funcall     # direct function call

            case addrvar     # address of a variable
            case getvar
            case setvar

            case addrgvar    # address of a global variable
            case getgvar
            case setgvar

            case deref       # dereference a pointer
            case setderef    # assign to a dereferenced address
            case ptrAdd      # add an int to a pointer
            case ptrSub      # subtract an int from a pointer
            case ptrDiff     # subtract two pointers

            case stmt        # GNU extension, statement expressions

            def repr(self): String = tag_name!(self)
            def __eq(self, other: Self): Bool = self is other
            def hash(self): Int = tag!(self)
        }
        val mark: Mark
        val kind: Kind
        var type: Type = ?
        var intValue: Int = ?
        var stringValue: String = ?
        var bytesValue: Uint8Array = ?
        var var_: Var = ?
        var gvar: GVar = ?
        var func: Func = ?
        var arg: Expr = ?
        var lhs: Expr = ?
        var rhs: Expr = ?
        var args: List[Expr] = ?
        var stmt: Stmt = ?
        def repr(self): String {
            val sb = StringBuilder()
            sb.str("{\"kind\":\"" + kind + "\"")
            if is_set!(self, type) { sb.str(",\"type\":\"" + type + "\"") }
            if is_set!(self, intValue) { sb.str(",\"intValue\":" + intValue) }
            if is_set!(self, var_) { sb.str(",\"var\":\"" + var_.index + "/" + var_.name + "\"") }
            if is_set!(self, gvar) { sb.str(",\"gvar\":\"" + gvar.name + "\"") }
            if is_set!(self, func) { sb.str(",\"func\":\"" + func.name + "\"") }
            if is_set!(self, arg) { sb.str(",\"arg\":" + arg.repr()) }
            if is_set!(self, lhs) { sb.str(",\"lhs\":" + lhs.repr()) }
            if is_set!(self, rhs) { sb.str(",\"rhs\":" + rhs.repr()) }
            if is_set!(self, args) { sb.str(",\"args\":" + args.repr()) }
            if is_set!(self, stmt) { sb.str(",\"stmt\":" + stmt.repr()) }
            sb.str("}")
            sb.toString()
        }
        ## Indicates that the expression has no visible side-effects.
        ## If the result of the expression is not used, it may be discarded.
        def isPure(self): Bool = when kind {
            case int = true
            else = false
        }
    }
}
