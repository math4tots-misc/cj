package cjx.cc

import cj.BigInt
import cj.Uint8Array
import cj.Error

class C2Token: Repr {
    enum {
        tEOF = 200
        tINT
        tLONG
        tCHAR
        tIDENT
        tSTR

        tEQ     # ==
        tNE     # !=
        tLE     # <=
        tGE     # >=
        tDECR   # --
        tINCR   # ++
        tARROW  # ->

        kwVOID
        kwUNSIGNED
        kwINT
        kwCHAR
        kwLONG
        kwSHORT
        kwBOOL
        kwTRUE
        kwFALSE
        kwDOUBLE
        kwSTRUCT
        kwUNION
        kwTYPEDEF
        kwRETURN
        kwIF
        kwELSE
        kwFOR
        kwWHILE
        kwSIZEOF
    }

    static val keywordTypes: List[Int] = static_field_values!(Self, "kw[A-Z]+")

    static val typeNameMap: Map[Int, String] = Map(
        static_field_name_value_pairs!(Self, "(kw|t)[A-Z]+").map(p -> (p.f1, p.f0)))

    val type : Int
    val value: Value
    val line : Int
    val column : Int
    var filepath: String

    @implicit(Unit, fromUnit)
    @implicit(Int, int)
    @implicit(BigInt, bigInt)
    @implicit(String, string)
    @implicit(Uint8Array, bytes)
    union Value : Repr {
        case none
        case int(Int)
        case bigInt(BigInt)
        case string(String)
        case bytes(Uint8Array)
        def fromUnit(u: Unit): Self = none
        def repr(self): String = when self {
            case none = "none"
            else(x) = x.repr()
        }
    }

    def __get_intValue(self): Int = when value {
        case int(x) = x
        else = throw Error("Expected int value but got " + value)
    }

    def __get_bigIntValue(self): BigInt = when value {
        case bigInt(x) = x
        else = throw Error("Expected bigInt value but got " + value)
    }

    def __get_stringValue(self): String = when value {
        case string(x) = x
        else = throw Error("Expected string value but got " + value)
    }

    def __get_bytesValue(self): Uint8Array = when value {
        case bytes(x) = x
        else = throw Error("Expected bytes value but got " + value)
    }

    def repr(self): String = (
        "C2Token(" + typeRepr(type) + ", " + value + ", " + line + ", " + column + ")")

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
