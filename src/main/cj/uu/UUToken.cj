package uu

import cj.BigInt

class UUToken : Repr {

    # Token types
    # (Single character symbolic tokens are represented by their
    # ASCII value, but all other token types need to be explicitly
    # enumerated here)
    enum {
        # general categories
        tEOF = 200
        tDOUBLE
        tINT
        tID
        tCHAR
        tSTRING
        tTYPEID
        tCOMMENT
        tBIGINT
        tMACROID

        # multi-character symbols
        tDOTDOT
        tMINUSMINUS
        tPLUSPLUS
        tRSHIFTU
        tEQ
        tNE
        tLE
        tGE
        tLSHIFT
        tRSHIFT
        tTRUNCDIV
        tPOWER
        tRIGHT_ARROW
        tPLUS_EQ
        tMINUS_EQ
        tSTAR_EQ
        tDIV_EQ
        tTRUNCDIV_EQ
        tREM_EQ

        # keywords
        kwDEF
        kwCLASS
        kwTRUE
        kwFALSE
        kwNULL
        kwIF
        kwELSE
        kwIMPORT
        kwWHILE
        kwBREAK
        kwCONTINUE
        kwVAR
        kwVAL
        kwTRAIT
        kwNATIVE
        kwSTATIC
        kwPRIVATE
        kwPUBLIC
        kwPACKAGE
        kwRETURN
        kwAND
        kwOR
        kwIS
        kwNOT
        kwIN
        kwSWITCH
        kwCASE
        kwUNION
        kwENUM
        kwWHEN
        kwAS
        kwFOR
        kwASYNC
        kwAWAIT
        kwTHROW
        kwTRY
        kwCATCH
        kwFINALLY
        kwINTERFACE
        kwSTRUCT
    }

    static val keywordTypes: List[Int] = static_field_values!(Self, "kw[A-Z]+")

    static val typeNameMap: Map[Int, String] = Map(
        static_field_name_value_pairs!(Self, "(kw|t)[A-Z]+").map(p -> (p.f1, p.f0)))

    val type : Int
    val value: Value
    val line : Int
    val column : Int

    union Value: Repr {
        case none
        case string(String)
        case int(Int)
        case char(Char)
        case bigInt(BigInt)
        case double(Double)
        def repr(self): String = when self { case none = "none"; else(v) = v.repr() }
    }
    def __get_stringValue(self): String = get!(value, string, 0)
    def __get_intValue(self): Int = get!(value, int, 0)
    def __get_charValue(self): Char = get!(value, char, 0)
    def __get_bigIntValue(self): BigInt = get!(value, bigInt, 0)
    def __get_doubleValue(self): Double = get!(value, double, 0)

    def repr(self): String = (
        "UUToken(" + typeRepr(type) + ", " + value.repr() + ", " + line + ", " + column + ")")

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
