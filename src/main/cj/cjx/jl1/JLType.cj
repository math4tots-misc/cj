package cjx.jl1

import cj.Error
import cjx.jl1.JLIRClass

union JLType: ToString, Eq {
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

    def isObject(self): Bool = when self {
        case klass(cls) = cls.name == "java.lang.Object"
        else = false
    }

    def isInterface(self): Bool = when self {
        case klass(cls) = cls.isInterface()
        else = false
    }

    def __get_arrayInnerType(self): Self = when self {
        case array(inner) = inner
        else = throw Error("FUBAR: expected array type")
    }

    def __eq(self, other: Self): Bool = when self {
        case void = when other { case void = true; else = false }
        case bool = when other { case bool = true; else = false }
        case byte = when other { case byte = true; else = false }
        case char = when other { case char = true; else = false }
        case short = when other { case short = true; else = false }
        case int = when other { case int = true; else = false }
        case long = when other { case long = true; else = false }
        case float = when other { case float = true; else = false }
        case double = when other { case double = true; else = false }
        case array(inner) = when other { case array(oinner) = inner == oinner; else = false }
        case klass(cls) = when other { case klass(ocls) = cls is ocls; else = false }
    }
}
