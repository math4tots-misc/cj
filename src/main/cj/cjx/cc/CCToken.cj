package cjx.cc

import cj.Error

class CCToken {
    static val tEOF = 201
    static val tINT = 202

    static val tEQ = 251
    static val tLE = 252
    static val tGE = 253

    static val kwINT = 301

    static val keywordTypes: List[Int] = static_field_values!(Self, "kw[A-Z]+")

    static val typeNameMap: Map[Int, String] = Map(
        static_field_name_value_pairs!(Self, "(kw|t)[A-Z]+").map(p -> (p.f1, p.f0)))

    val type : Int
    val value: Value
    val line : Int
    val column : Int

    @implicit(Unit, fromUnit)
    @implicit(Int, int)
    @implicit(String, string)
    union Value : Repr {
        case none
        case int(Int)
        case string(String)
        def fromUnit(u: Unit): Self = none
        def repr(self): String = when self {
            case none = "none"
            case string(s) = s.repr()
            case int(i) = i.repr()
        }
    }

    def __get_intValue(self): Int = when value {
        case int(x) = x
        else = throw Error("Expected int value but got " + value)
    }

    def __get_stringValue(self): String = when value {
        case string(x) = x
        else = throw Error("Expected string value but got " + value)
    }

    def repr(self): String = (
        "CCToken(" + typeRepr(type) + ", " + value + ", " + line + ", " + column + ")")

    def keywordString(type: Int): String = {
        val str = typeRepr(type)
        Assert.withMessage(str.startsWith("kw"), str)
        str["kw".size():].lower()
    }

    def typeRepr(type: Int): String {
        if val name = typeNameMap.getOrNull(type) {
            name
        } else if type == '\n' or type >= 32 and type <= 127 {
            type.toChar().repr()
        } else {
            "Unknown(" + type + ")"
        }
    }
}
