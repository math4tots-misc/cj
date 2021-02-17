package compiler

class CJToken : Repr {
    # general categories (1-10)
    static val tEOF = 1
    static val tDOUBLE = 2
    static val tINT = 3
    static val tID = 4
    static val tCHAR = 5
    static val tSTRING = 6
    static val tTYPEID = 7
    static val tCOMMENT = 8
    static val tBIGINT = 9

    # multi-character symbols (13-31)
    static val tDOTDOT = 13
    static val tMINUSMINUS = 14
    static val tPLUSPLUS = 15
    static val tRSHIFTU = 16
    static val tEQ = 17
    static val tNE = 18
    static val tLE = 19
    static val tGE = 20
    static val tLSHIFT = 21
    static val tRSHIFT = 22
    static val tTRUNCDIV = 23
    static val tPOWER = 24
    static val tRIGHT_ARROW = 25
    static val tPLUS_EQ = 26
    static val tMINUS_EQ = 27
    static val tSTAR_EQ = 28
    static val tDIV_EQ = 29
    static val tTRUNCDIV_EQ = 30
    static val tREM_EQ = 31

    # token types in the range 32-127 are reserved for ASCII single character
    # token types.

    # keywords (200+)
    static val kwDEF = 201
    static val kwCLASS = 202
    static val kwTRUE = 203
    static val kwFALSE = 204
    static val kwNULL = 205
    static val kwIF = 206
    static val kwELSE = 207
    static val kwIMPORT = 208
    static val kwWHILE = 209
    static val kwBREAK = 210
    static val kwCONTINUE = 211
    static val kwVAR = 212
    static val kwVAL = 213
    # static val kwNEW = 214
    static val kwTRAIT = 215
    static val kwNATIVE = 216
    static val kwSTATIC = 217
    static val kwPRIVATE = 218
    static val kwPUBLIC = 219
    static val kwPACKAGE = 220
    static val kwRETURN = 221
    static val kwAND = 222
    static val kwOR = 223
    static val kwIS = 224
    static val kwNOT = 225
    static val kwIN = 226
    # static val kwTHEN = 227
    static val kwSWITCH = 228
    static val kwCASE = 229
    static val kwUNION = 230
    static val kwENUM = 231
    static val kwWHEN = 232
    static val kwAS = 233
    static val kwFOR = 234
    static val kwASYNC = 235
    static val kwAWAIT = 236
    static val kwTHROW = 237
    static val kwTRY = 238
    static val kwCATCH = 239
    static val kwFINALLY = 240

    static val keywordTypes: List[Int] = [
        kwDEF, kwCLASS, kwTRUE, kwFALSE, kwNULL, kwIF, kwELSE, kwIMPORT, kwWHILE, kwBREAK,
        kwCONTINUE, kwVAR, kwVAL, kwTRAIT, kwNATIVE, kwSTATIC, kwPRIVATE, kwPUBLIC, kwPACKAGE,
        kwRETURN, kwAND, kwOR, kwIS, kwNOT, kwIN, kwSWITCH, kwCASE, kwUNION, kwENUM, kwWHEN,
        kwAS, kwFOR, kwASYNC, kwAWAIT, kwTHROW, kwTRY, kwCATCH, kwFINALLY,
    ]

    val type : Int
    val text : String
    val line : Int
    val column : Int

    def repr(self): String = (
        "CJToken(" + typeRepr(type) + ", " + text.repr() + ", " + line + ", " + column + ")")

    def keywordString(type: Int): String = {
        val str = typeRepr(type)
        Assert.withMessage(str.startsWith("kw"), str)
        str["kw".size():].lower()
    }

    def typeRepr(type: Int): String = switch type {
        case tEOF = "tEOF"
        case tDOUBLE = "tDOUBLE"
        case tINT = "tINT"
        case tID = "tID"
        case tCHAR = "tCHAR"
        case tSTRING = "tSTRING"
        case tTYPEID = "tTYPEID"
        case tCOMMENT = "tCOMMENT"
        case tBIGINT = "tBIGINT"
        case tDOTDOT = "tDOTDOT"
        case tMINUSMINUS = "tMINUSMINUS"
        case tPLUSPLUS = "tPLUSPLUS"
        case tRSHIFTU = "tRSHIFTU"
        case tEQ = "tEQ"
        case tNE = "tNE"
        case tLE = "tLE"
        case tGE = "tGE"
        case tLSHIFT = "tLSHIFT"
        case tRSHIFT = "tRSHIFT"
        case tTRUNCDIV = "tTRUNCDIV"
        case tPOWER = "tPOWER"
        case tRIGHT_ARROW = "tRIGHT_ARROW"
        case tPLUS_EQ = "tPLUS_EQ"
        case tMINUS_EQ = "tMINUS_EQ"
        case tSTAR_EQ = "tSTAR_EQ"
        case tDIV_EQ = "tDIV_EQ"
        case tTRUNCDIV_EQ = "tTRUNCDIV_EQ"
        case tREM_EQ = "tREM_EQ"
        case kwDEF = "kwDEF"
        case kwCLASS = "kwCLASS"
        case kwTRUE = "kwTRUE"
        case kwFALSE = "kwFALSE"
        case kwNULL = "kwNULL"
        case kwIF = "kwIF"
        case kwELSE = "kwELSE"
        case kwIMPORT = "kwIMPORT"
        case kwWHILE = "kwWHILE"
        case kwBREAK = "kwBREAK"
        case kwCONTINUE = "kwCONTINUE"
        case kwVAR = "kwVAR"
        case kwVAL = "kwVAL"
        case kwTRAIT = "kwTRAIT"
        case kwNATIVE = "kwNATIVE"
        case kwSTATIC = "kwSTATIC"
        case kwPRIVATE = "kwPRIVATE"
        case kwPUBLIC = "kwPUBLIC"
        case kwPACKAGE = "kwPACKAGE"
        case kwRETURN = "kwRETURN"
        case kwAND = "kwAND"
        case kwOR = "kwOR"
        case kwIS = "kwIS"
        case kwNOT = "kwNOT"
        case kwIN = "kwIN"
        case kwSWITCH = "kwSWITCH"
        case kwCASE = "kwCASE"
        case kwUNION = "kwUNION"
        case kwENUM = "kwENUM"
        case kwWHEN = "kwWHEN"
        case kwAS = "kwAS"
        case kwFOR = "kwFOR"
        case kwASYNC = "kwASYNC"
        case kwAWAIT = "kwAWAIT"
        case kwTHROW = "kwTHROW"
        case kwTRY = "kwTRY"
        case kwCATCH = "kwCATCH"
        case kwFINALLY = "kwFINALLY"
        case '\n' = "'\\n'"
        else = if type >= 32 and type <= 127 { type.toChar().repr() } else {
            "Unknown(" + type + ")"
        }
    }
}
