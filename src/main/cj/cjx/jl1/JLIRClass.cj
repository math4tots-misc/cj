package cjx.jl1

import cjx.jl1.JLIRField
import cjx.jl1.JLIRMethod
import cjx.jl1.JLType
import cjx.jl1.JLMark

@derive(new)
class JLIRClass {
    union Kind {
        case klass
        case iface
    }

    val mark: JLMark
    val modifiers: List[String]
    val kind: Kind
    val name: String  # fully qualified name
    val interfaces: List[JLType] = []
    val fields: List[JLIRField] = []
    val methods: List[JLIRMethod] = []

    def isNative(self): Bool = "native" in modifiers
    def toJVMName(self): String = name.replace(".", "/")
    def isInterface(self): Bool = when self.kind {
        case iface = true
        case klass = false
    }
}
