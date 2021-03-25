package cjx.cc2

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
    union Type: Repr {
        class Func {
            val returnType: Type
            val params: List[Var]
        }
        class Ptr {
            val target: Type
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
        val type: Type
        var body: Stmt = ?
        var locals: List[Var] = ?
        def __get_params(self): List[Var] = locals[:type.params.size()]
    }
    class Stmt {
        union Kind: Repr, Hash {
            case block
            case expr
            case ret
            def repr(self): String = tag_name!(self)
            def __eq(self, other: Self): Bool = self is other
            def hash(self): Int = tag!(self)
        }
        val mark: Mark
        val kind: Kind
        var stmts: List[Stmt] = ?
        var expr: Expr = ?
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
    }
}
