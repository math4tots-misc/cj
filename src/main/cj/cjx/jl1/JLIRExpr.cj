package cjx.jl1

import cjx.jl1.JLIRLocal
import cjx.jl1.JLIRFieldRef
import cjx.jl1.JLIRMethodRef
import cj.BigInt
import cjx.jl1.JLType
import cjx.jl1.JLMark

## jl1 expression
class JLIRExpr {

    union Data {
        case boolean(Bool)
        case int(Int)
        case long(BigInt)
        case float(Double)
        case double(Double)
        case string(String)
        case block(List[Self])
        case call(JLIRMethodRef, List[Self])
        case declarelocal(JLIRLocal) # declare a local variable
        case getlocal(JLIRLocal) # get local variable
        case setlocal(JLIRLocal, Self) # set local variable
        case getstatic(JLIRFieldRef) # get static field
        case setstatic(JLIRFieldRef, Self) # set static field
        case getfield(JLIRFieldRef, Self) # get instance field
        case setfield(JLIRFieldRef, Self, Self) # set instance field

        ## "Manually" call a Java method
        ##
        ## Allows invoking overloaded methods by specifying the full method signature
        ##
        ## (is-static, owner-type, method-name, signature, args)
        case calldirect(Bool, JLType, String, String, List[Self])
    }

    val mark: JLMark
    val type: JLType
    val data: Data
}
