package cjx.cc

import cjx.parser.MError
import cj.BigInt
import cj.Uint8Array
import cjx.cc.C2Locals
import cj.StringBuilder
import cj.Error
import cjx.parser.Mark

class C2IR {
    class TranslationUnit {
        val gvars: List[GVar] = []
        val funcs: List[Func] = []
        val map: Map[String, Ordinary] = MapOf()
        def addFunc(self, func: Func) {
            funcs.add(func)
            _add(func.name, func)
        }
        def addGVar(self, gvar: GVar) {
            gvars.add(gvar)
            _add(gvar.name, gvar)
        }
        def addEnumConstant(self, ec: EnumConstant) {
            _add(ec.name, ec)
        }
        def addTypedef(self, typedef: Typedef) {
            _add(typedef.name, typedef)
        }
        def _add(self, name: String, ordinary: Ordinary) {
            if name in map {
                throw MError("'" + name + "' already defined in this scope", [ordinary.mark])
            }
            map[name] = ordinary
        }
        def getOrNull(self, name: String): Ordinary? = map.getOrNull(name)
    }
    @implicit(GVar, gvar)
    @implicit(Var, lvar)
    @implicit(Func, func)
    @implicit(Typedef, typedef)
    @implicit(EnumConstant, enumConstant)
    union Ordinary {
        case gvar(GVar)
        case lvar(Var)
        case func(Func)
        case typedef(Typedef)
        case enumConstant(EnumConstant)
        def __get_name(self): String = when self { else(x) = x.name }
        def __get_mark(self): Mark = when self { else(x) = x.mark }
    }
    class EnumConstant {
        val mark: Mark
        val name: String
        val value: Int
    }
    class Typedef {
        val mark: Mark
        val name: String
        val type: Type
    }
    ## Variable attributes such as typedef or extern
    class VarAttr: ToBool {
        var typedef = false
        var static_ = false
        def add(self, other: Self) {
            typedef = typedef or other.typedef
            static_ = static_ or other.static_
        }
        def toBool(self): Bool = typedef or static_
    }
    @implicit(Type.Derived, derived)
    union Taggable {
        case derived(Type.Derived)
        def __get_mark(self): Mark = when self { else(t) = t.mark }
        def __get_tag(self): String? = when self { else(t) = t.tag }
    }
    @implicit(Type.Derived, derived)
    @implicit(Type.Func, func)
    union Type: Repr, Eq {
        class Func: Eq {
            val returnType: Type
            val params: List[Var]
            def __get_paramTypes(self): List[Type] = params.map(p -> p.type)
            def __eq(self, other: Self): Bool = (
                returnType == other.returnType and paramTypes == other.paramTypes)
        }
        class Ptr: Eq {
            val base: Type
            def __eq(self, other: Self): Bool = base == other.base
        }
        class Array: Eq {
            val base: Type
            val len: Int
            def __eq(self, other: Self): Bool = base == other.base and len == other.len
        }
        ## Struct or Union
        ## Seen another way, a union is basically a struct where all member offsets are zero.
        class Derived: Eq {
            class Member: Eq {
                val mark: Mark
                val name: String
                val type: Type
                var offset: Int
                def __eq(self, other: Self): Bool = name == other.name and type == other.type
            }
            val mark: Mark
            val _isUnion: Bool
            val tag: String?
            val members: List[Member] = []
            var _size: Int = ?
            var _alignment: Int = ?
            def size(self): Int = _size
            def alignment(self): Int = _alignment
            def isComplete(self): Bool = is_set!(self, _size)
            def __eq(self, other: Self): Bool = (
                _isUnion == other._isUnion and members == other.members)
            def getMemberOrNull(self, memberName: String): Member? {
                for member in members {
                    if member.name == memberName {
                        return null(member)
                    }
                }
                null
            }
            def isUnion(self): Bool = _isUnion
        }
        case void
        case bool
        case char  # NOTE: char is unsigned
        case int
        case short
        case long
        case ptr(Ptr)
        case array(Array)
        case func(Func)
        case derived(Derived)
        def isVoid(self): Bool = tag!(self) == tag!(Self, void)
        def isChar(self): Bool = tag!(self) == tag!(Self, char)
        def isInt(self): Bool = tag!(self) == tag!(Self, int)
        def isShort(self): Bool = tag!(self) == tag!(Self, short)
        def isLong(self): Bool = tag!(self) == tag!(Self, long)
        def isPtr(self): Bool = tag!(self) == tag!(Self, ptr)
        def isDerived(self): Bool = tag!(self) == tag!(Self, derived)
        def isArray(self): Bool = tag!(self) == tag!(Self, array)
        def isFunc(self): Bool = tag!(self) == tag!(Self, func)
        def isPtrOrArray(self): Bool = isPtr() or isArray()
        def rank(self): Int {
            when self {
                case bool = 0
                case char = 1
                case short = 2
                case int = 3
                case long = 4
                else = throw MError("Rank does not apply to non-integral type " + self, [])
            }
        }
        def isSigned(self): Bool {
            when self {
                case short; case int; case long = true
                case char = false
                else = throw MError("non-integral type " + self + " does not have signedness", [])
            }
        }
        ## More info on incomplete types:
        ## https://docs.oracle.com/cd/E19205-01/819-5265/bjals/index.html
        def isComplete(self): Bool = when self {
            case void = false
            case derived(s) = s.isComplete()
            else = true
        }
        def isIntegral(self): Bool = when self {
            case bool; case char; case int; case short; case long = true
            else = false
        }
        def repr(self): String = when self {
            case ptr(p) = "ptr(" + p.base + ")"
            case array(a) = "array(" + a.base + "," + a.len + ")"
            case func(f) = "func(" + f.returnType + "," + f.params + ")"
            case derived(s) = {
                val kind = if s.isUnion() { "union" } else { "struct" }
                if val tag = s.tag { kind + "(" + tag + ")" } else { kind + "(..)" }
            }
            else name() = name
        }
        def __eq(self, other: Self): Bool = tag!(self) == tag!(other) and when self {
            case ptr(p) = p == get!(other, ptr, 0)
            case array(a) = a == get!(other, array, 0)
            case func(f) = f == get!(other, func, 0)
            case derived(s) = s == get!(other, derived, 0)
            else() = true
        }
        def ptrOf(t: Type): Type = Type.ptr(Ptr(t))
        def arrayOf(t: Type, len: Int): Type = Type.array(Array(t, len))
        def size(self): Int = when self {
            case bool = 1
            case char = 1
            case short = 2
            case long = 8
            case void; case int; case ptr(..); case func(..) = 4
            case array(a) = a.len * a.base.size()
            case derived(x) = x.size()
        }
        def alignment(self): Int = when self {
            case array(a) = a.base.alignment()
            case derived(x) = x.alignment()
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
        val attr: VarAttr
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
        var vars: List[Var] = ?

        def repr(self): String {
            val sb = StringBuilder()
            sb.str("{\"kind\":\"" + kind + "\"")
            if is_set!(self, stmts) { sb.str(",\"stmts\":" + stmts.repr()) }
            if is_set!(self, expr) { sb.str(",\"expr\":" + expr.repr()) }
            if is_set!(self, cond) { sb.str(",\"cond\":" + cond.repr()) }
            if is_set!(self, then) { sb.str(",\"then\":" + then.repr()) }
            if is_set!(self, els) { sb.str(",\"els\":" + els.repr()) }
            if is_set!(self, vars) { sb.str(",\"vars\":" + vars.map(v -> v.name + "/" + v.index) + "") }
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
            case intBitwiseNot

            case long
            case longNeg
            case longAdd
            case longSub
            case longMul
            case longDiv
            case longRem
            case longEq
            case longNe
            case longLt
            case longLe

            case short
            case bool
            case char        # NOTE: char is unsigned

            case str

            case cast

            case comma

            case logicalNot

            case getmember   # derived member access
            case setmember

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
        var bigIntValue: BigInt = ?  # for long
        var stringValue: String = ?
        var bytesValue: Uint8Array = ?
        var var_: Var = ?
        var vars: List[Var] = ?
        var gvar: GVar = ?
        var func: Func = ?
        var arg: Expr = ?
        var lhs: Expr = ?
        var rhs: Expr = ?
        var args: List[Expr] = ?
        var stmts: List[Stmt] = ?
        var member: Type.Derived.Member = ?
        def repr(self): String {
            val sb = StringBuilder()
            sb.str("{\"kind\":\"" + kind + "\"")
            if is_set!(self, type) { sb.str(",\"type\":\"" + type + "\"") }
            if is_set!(self, intValue) { sb.str(",\"intValue\":" + intValue) }
            if is_set!(self, bigIntValue) { sb.str(",\"bigIntValue\":\"" + bigIntValue + "\"") }
            if is_set!(self, var_) { sb.str(",\"var\":\"" + var_.index + "/" + var_.name + "\"") }
            if is_set!(self, vars) { sb.str(",\"vars\":" + vars.map(v -> "\"" + v + "\"") + "") }
            if is_set!(self, gvar) { sb.str(",\"gvar\":\"" + gvar.name + "\"") }
            if is_set!(self, func) { sb.str(",\"func\":\"" + func.name + "\"") }
            if is_set!(self, arg) { sb.str(",\"arg\":" + arg.repr()) }
            if is_set!(self, lhs) { sb.str(",\"lhs\":" + lhs.repr()) }
            if is_set!(self, rhs) { sb.str(",\"rhs\":" + rhs.repr()) }
            if is_set!(self, args) { sb.str(",\"args\":" + args.repr()) }
            if is_set!(self, stmts) { sb.str(",\"stmts\":" + stmts.repr()) }
            if is_set!(self, member) { sb.str(",\"member\":\"" + member.offset + "/" + member.name + "\"") }
            sb.str("}")
            sb.toString()
        }
    }
}
