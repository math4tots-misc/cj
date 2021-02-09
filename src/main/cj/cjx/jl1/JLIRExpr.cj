package cjx.jl1

import cjx.jl1.JLIRLocal
import cjx.jl1.JLIRFieldRef
import cjx.jl1.JLIRMethodRef
import cj.BigInt
import cjx.jl1.JLType
import cjx.jl1.JLMark

## jl1 expression
@derive(new)
class JLIRExpr {

    union Data {
        case void()
        case bool(Bool)
        case char(Int)
        case int(Int)
        case long(BigInt)
        case float(Double)
        case double(Double)
        case string(String)
        case block(List[JLIRExpr])
        case call(JLIRMethodRef, List[JLIRExpr])
        case declarelocal(JLIRLocal, JLIRExpr) # declare a local variable
        case getlocal(JLIRLocal) # get local variable
        case setlocal(JLIRLocal, JLIRExpr) # set local variable
        case getstatic(JLIRFieldRef) # get static field
        case setstatic(JLIRFieldRef, JLIRExpr) # set static field
        case getfield(JLIRFieldRef, JLIRExpr) # get instance field
        case setfield(JLIRFieldRef, JLIRExpr, JLIRExpr) # set instance field
        case if_(JLIRExpr, JLIRExpr, JLIRExpr)

        case operation(Operator, List[JLIRExpr])

        ## "Manually" call a Java method
        ##
        ## Allows invoking overloaded methods by specifying the full method signature
        ##
        ## (kind(static, virtual or interface), owner-type, method-name, signature, args)
        case calljava(String, String, String, String, List[JLIRExpr])
    }

    union Operator {
        case intAdd
        case intSub

        case doubleAdd

        case stringAdd

        case l2i
    }

    val mark: JLMark
    val type: JLType
    val data: Data

    def isEmpty(self): Bool = when data {
        case void() = true
        case block(exprs) = exprs.isEmpty()
        else = false
    }
}
