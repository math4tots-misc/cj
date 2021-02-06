package cjx.jl1

import cjx.jl1.JLMark

@derive(new)
class JLToken: Repr {

    # general categories (1-15)
    static val tEOF = 1
    static val tCOMMENT = 2
    static val tID = 3
    static val tTYPEID = 4
    static val tINT = 5
    static val tCHAR = 6
    static val tSHORT = 7
    static val tLONG = 8
    static val tDOUBLE = 9
    static val tFLOAT = 10
    static val tSTRING = 11

    # token types in the range 32-127 are restricted for ASCII single character
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
    static val kwINTERFACE = 241

    static val keywordTypes: List[Int] = [
        kwDEF, kwCLASS, kwTRUE, kwFALSE, kwNULL, kwIF, kwELSE, kwIMPORT, kwWHILE, kwBREAK,
        kwCONTINUE, kwVAR, kwVAL, kwTRAIT, kwNATIVE, kwSTATIC, kwPRIVATE, kwPUBLIC, kwPACKAGE,
        kwRETURN, kwAND, kwOR, kwIS, kwNOT, kwIN, kwSWITCH, kwCASE, kwUNION, kwENUM, kwWHEN,
        kwAS, kwFOR, kwASYNC, kwAWAIT, kwTHROW, kwTRY, kwCATCH, kwFINALLY, kwINTERFACE,
    ]

    static val modifierKeywordTypes: Set[Int] = Set(
        kwPUBLIC, kwPRIVATE, kwSTATIC)

    val type: Int
    val text: String
    val line: Int
    val column: Int

    def repr(self): String = (
        "JLToken(" + typeRepr(type) + ", " + text.repr() + ", " + line + ", " + column + ")")

    def toMark(self, filename: String): JLMark = JLMark(filename, line, column)

    def keywordString(type: Int): String = {
        val str = typeRepr(type)
        Assert.withMessage(str.startsWith("kw"), str)
        str["kw".size():].lower()
    }

    def typeRepr(type: Int): String = switch type {
        case tEOF = "tEOF"
        case tCOMMENT = "tCOMMENT"
        case tID = "tID"
        case tTYPEID = "tTYPEID"
        case tINT = "tINT"
        case tCHAR = "tCHAR"
        case tSHORT = "tSHORT"
        case tLONG = "tLONG"
        case tDOUBLE = "tDOUBLE"
        case tFLOAT = "tFLOAT"
        case tSTRING = "tSTRING"
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
        case kwINTERFACE = "kwINTERFACE"
        case '\n' = "'\\n'"
        else = if type >= 32 and type <= 127 { type.toChar().repr() } else {
            "Unknown(" + type + ")"
        }
    }
}
