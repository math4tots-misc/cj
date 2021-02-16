package cjx.xx.llir

import cjx.xx.llir.XXLLIRLocals
import cjx.xx.llir.XXLLIRExpr
import cjx.xx.llir.XXLLIRType
import cjx.xx.llir.XXLLIRLocal
import cjx.xx.XXMark

class XXLLIRMethod {
    val mark: XXMark
    val modifiers: List[String]
    val name: String
    val parameters: List[Int] # index into self.locals
    val returnType: XXLLIRType
    val body: Nullable[XXLLIRExpr]

    ## contains all XXLLIRLocal values referenced in this method
    val locals: XXLLIRLocals

    def isStatic(self): Bool = "static" in modifiers
}
