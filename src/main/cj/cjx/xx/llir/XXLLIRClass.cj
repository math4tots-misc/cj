package cjx.xx.llir

import cjx.xx.llir.XXLLIRMethod
import cjx.xx.llir.XXLLIRField
import cjx.xx.XXMark

@derive(new)
class XXLLIRClass: Repr {
    val mark: XXMark
    val modifiers: List[String]
    val name: String
    var superClass = "java.lang.Object"
    val interfaces: List[String] = []
    val fields: List[XXLLIRField] = []
    val methods: List[XXLLIRMethod] = []
    def isInterface(self): Bool = "interface" in modifiers
    def isNative(self): Bool = "native" in modifiers
    def isFinal(self): Bool = "final" in modifiers
    def repr(self): String = "llir(" + name + ")"
}
