package cjx.jl1

import cjx.jl1.JLIRClass

union JLType: ToString {
    case void
    case boolean
    case byte
    case char
    case short
    case int
    case long
    case float
    case double
    case klass(JLIRClass)

    def toString(self): String = when self {
        case void() = "void"
        case boolean() = "boolean"
        case byte() = "byte"
        case char() = "char"
        case short() = "short"
        case int() = "int"
        case long() = "long"
        case float() = "float"
        case double() = "double"
        case klass(cls) = cls.name
    }

    def toJVMString(self): String = when self {
        case void() = "V"
        case boolean() = "Z"
        case byte() = "B"
        case char() = "C"
        case short() = "S"
        case int() = "I"
        case long() = "J"
        case float() = "F"
        case double() = "D"
        case klass(cls) = "L" + cls.toJVMName() + ";"
    }
}
