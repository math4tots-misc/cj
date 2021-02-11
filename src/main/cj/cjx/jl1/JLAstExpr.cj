package cjx.jl1

import cjx.jl1.JLAstMetaExpr
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
        case callnew(JLAstType, List[JLAstExpr])
        case calltype(JLAstType, List[JLAstExpr]) # call a type like a function
        case callstatic(JLAstType, String, List[JLAstExpr])
        case callinstance(String, List[JLAstExpr])
        case callname(String, List[JLAstExpr])
        case getstatic(JLAstType, String)
        case setstatic(JLAstType, String, JLAstExpr)
        case getfield(JLAstExpr, String)
        case setfield(JLAstExpr, String, JLAstExpr)
        case getvar(String)
        case setvar(String, JLAstExpr)
        case declvar(JLAstLocal)
        case this()
        case if_(JLAstExpr, JLAstExpr, Nullable[JLAstExpr])
        case while_(JLAstExpr, JLAstExpr)
        case operation(Operator, List[JLAstExpr])

        case meta(JLAstMetaExpr)

        ## (kind(static,virtual,interface,special),
        ##   returnType, className, methodName, descriptor, args)
        case javacall(String, JLAstType, String, String, String, List[JLAstExpr])

        ## (returnType, className, descriptor, args)
        case javanew(JLAstType, String, String, List[JLAstExpr])

        # ================================================================================
        # special <init> and <clinit> helpers
        # ================================================================================

        ## Initializes a static or non-static field.
        ## Not for direct use (i.e. the parser should never generate this).
        ## Nodes of this kind are automatically generated for <init> and <clinit> methods.
        case initfield(String, JLAstExpr)
    }

    @derive(repr)
    union Operator: Hash {
        case add
        case sub
        case mul
        case div
        case rem
        case and_
        case or_
        case xor
        case shl
        case shr
        case shru
        case neg
        case pow
        case lt
        case le
        case gt
        case ge
        case eq
        case ne

        case len
        case getitem
        case setitem
        case clearitem
        case slice
        case realloc

        def __eq(self, other: Self): Bool = repr() == other.repr()
        def hash(self): Int = repr().hash()
    }

    val mark: JLMark
    val data: Data
}
