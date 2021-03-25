package cjx.cc2

import cj.StringBuilder
import cj.Error
import cjx.parser.Mark

class C2IR {
    class TranslationUnit {
        val funcs: List[Func] = []
        val funcMap: Map[String, Func] = MapOf()
        def addFunc(self, func: Func) {
            Assert(func.name not in funcMap)
            funcs.add(func)
            funcMap[func.name] = func
        }
        def getFuncOrNull(self, name: String): Func? = funcMap.getOrNull(name)
    }
    union Type: Repr, Eq {
        class Func {
            val returnType: Type
            val params: List[Var]
            def __get_paramTypes(self): List[Type] = params.map(p -> p.type)
            def __eq(self, other: Self): Bool = (
                returnType == other.returnType and paramTypes == other.paramTypes)
        }
        class Ptr {
            val target: Type
            def __eq(self, other: Self): Bool = target == other.target
        }
        class Struct {
        }
        case void
        case int
        case ptr(Ptr)
        case func(Func)
        case struct_(Struct)
        def isVoid(self): Bool = tag!(self) == tag!(Self, void)
        def isInt(self): Bool = tag!(self) == tag!(Self, int)
        def isPtr(self): Bool = tag!(self) == tag!(Self, ptr)
        def isFunc(self): Bool = tag!(self) == tag!(Self, func)
        def repr(self): String = when self {
            case ptr(p) = "ptr(" + p.target + ")"
            case func(f) = "func(" + f.returnType + "," + f.params + ")"
            case struct_(s) = "struct()"
            else name() = name
        }
        def __eq(self, other: Self): Bool = tag!(self) == tag!(other) and when self {
            case ptr(p) = p == get!(other, ptr, 0)
            case func(f) = f == get!(other, func, 0)
            case struct_(s) = throw Error("TODO struct type equality")
            else = false
        }
        def __get_returnType(self): Type = get!(self, func, 0).returnType
        def __get_params(self): List[Var] = get!(self, func, 0).params
        def __get_paramTypes(self): List[Type] = params.map(v -> v.type)
    }
    class Var: Repr {
        val mark: Mark
        val name: String
        val type: Type
        val index: Int
        def repr(self): String = "Var(" + name + "," + type + "," + index + ")"
        def toString(self): String = ("" + type + " " + name).trim()
    }
    class Func {
        val mark: Mark
        val name: String
        val type: Type.Func
        var body: Stmt = ?
        var locals: List[Var] = ?
        def __get_params(self): List[Var] = locals[:type.params.size()]
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
    class Expr {
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
            case getvar
            case setvar
            def repr(self): String = tag_name!(self)
            def __eq(self, other: Self): Bool = self is other
            def hash(self): Int = tag!(self)
        }
        val mark: Mark
        val kind: Kind
        var type: Type = ?
        var intValue: Int = ?
        var var_: Var = ?
        var arg: Expr = ?
        var lhs: Expr = ?
        var rhs: Expr = ?
        def repr(self): String {
            val sb = StringBuilder()
            sb.str("{\"kind\":\"" + kind + "\"")
            if is_set!(self, intValue) { sb.str(",\"intValue\":" + intValue) }
            if is_set!(self, var_) { sb.str(",\"var\":\"" + var_.index + "/" + var_.name + "\"") }
            if is_set!(self, arg) { sb.str(",\"arg\":" + arg.repr()) }
            if is_set!(self, lhs) { sb.str(",\"lhs\":" + lhs.repr()) }
            if is_set!(self, rhs) { sb.str(",\"rhs\":" + rhs.repr()) }
            sb.str("}")
            sb.toString()
        }
    }
}
