package cjx.jl1

import cjx.jl1.JLMark
import cjx.jl1.JLIRExpr
import cjx.jl1.JLIRLocal
import cjx.jl1.JLType

class JLIRMethod {
    val mark: JLMark
    val comment: Nullable[String]
    val modifiers: List[String]
    val name: String
    val parameters: List[JLIRLocal]
    val returnType: JLType

    ## all local variables declared in this method, including 'this' and
    ## all parameters
    val locals: List[JLIRLocal]
    var body: Nullable[JLIRExpr] = null

    def isStatic(self): Bool = not (parameters and parameters[0].name == "this")

    def getJVMDescriptor(self): String = (
        "(" + "".join((
            if isStatic() { parameters } else { parameters[1:] }
        ).map(p -> p.type.toJVMString())) + ")" + returnType.toJVMString())
}
