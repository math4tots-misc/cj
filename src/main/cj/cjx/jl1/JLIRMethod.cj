package cjx.jl1

import cjx.jl1.JLMark
import cjx.jl1.JLIRExpr
import cjx.jl1.JLIRLocal
import cjx.jl1.JLType

@derive(new)
class JLIRMethod {
    val mark: JLMark
    val comment: Nullable[String]
    val modifiers: List[String]
    val localThis: Nullable[JLIRLocal]
    val name: String
    val parameters: List[JLIRLocal]
    val returnType: JLType

    ## all local variables declared in this method, including 'this' and
    ## all parameters
    val locals: List[JLIRLocal]
    var body: Nullable[JLIRExpr] = null

    def isStatic(self): Bool = localThis.isEmpty()

    def getJVMDescriptor(self): String = (
        "(" + "".join(parameters.map(p -> p.type.toJVMString())) + ")" + returnType.toJVMString())

    def newLocal(
            self,
            mark: JLMark,
            modifiers: List[String],
            name: String,
            type: JLType): JLIRLocal {
        val id = locals.size()
        val local = JLIRLocal(mark, id, modifiers, name, type)
        locals.add(local)
        local
    }
}
