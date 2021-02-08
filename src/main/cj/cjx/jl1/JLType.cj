package cjx.jl1

import cjx.jl1.JLIRClass

union JLType: ToString {
    case void
    case bool
    case byte
    case char
    case short
    case int
    case long
    case float
    case double
    case array(JLType)
    case klass(JLIRClass)

    def toString(self): String = when self {
        case void() = "void"
        case bool() = "bool"
        case byte() = "byte"
        case char() = "char"
        case short() = "short"
        case int() = "int"
        case long() = "long"
        case float() = "float"
        case double() = "double"
        case array(inner) = inner.toString() + "[]"
        case klass(cls) = cls.name
    }

    def toJVMString(self): String = when self {
        case void() = "V"
        case bool() = "Z"
        case byte() = "B"
        case char() = "C"
        case short() = "S"
        case int() = "I"
        case long() = "J"
        case float() = "F"
        case double() = "D"
        case array(inner) = "[" + inner.toJVMString()
        case klass(cls) = "L" + cls.toJVMName() + ";"
    }

    def getJVMSlotSize(self): Int = when self {
        case void() = 0
        case long() = 2
        case double() = 2
        else = 1
    }

    def isVoid(self): Bool = when self {
        case void = true
        else = false
    }

    def isInterface(self): Bool = when self {
        case klass(cls) = cls.isInterface()
        else = false
    }
}
