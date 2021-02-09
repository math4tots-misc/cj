package cjx.jl1

import cjx.jl1.JLAstLocal
import cjx.jl1.JLAstType
import cjx.jl1.JLMark

@derive(new)
class JLAstExpr {
    union Data {
        case bool(Bool)
        case char(Int)
        case int(Int)
        case double(Double)
        case string(String)
        case block(List[JLAstExpr])
        case callstatic(String, String, List[JLAstExpr])
        case callinstance(JLAstExpr, String, List[JLAstExpr])
        case callname(String, List[JLAstExpr])
        case getstatic(String, String)
        case setstatic(String, String, JLAstExpr)
        case getfield(JLAstExpr, String)
        case setfield(JLAstExpr, String, JLAstExpr)
        case getvar(String)
        case setvar(String, JLAstExpr)
        case declvar(JLAstLocal)
        case this()
        case if_(JLAstExpr, JLAstExpr, Nullable[JLAstExpr])
        case operation(Operator, List[JLAstExpr])

        ## (kind(static,virtual,interface), returnType, className, methodName, descriptor, args)
        case calljava(String, JLAstType, String, String, String, List[JLAstExpr])
    }

    union Operator: Hash, Repr {
        case add
        case sub

        def __eq(self, other: Self): Bool = repr() == other.repr()
        def hash(self): Int = repr().hash()
        def repr(self): String = when self {
            case add = "add"
            case sub = "sub"
        }
    }

    val mark: JLMark
    val data: Data
}
