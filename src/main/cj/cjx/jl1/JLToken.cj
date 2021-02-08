package cjx.jl1

import cjx.jl1.JLMark

@derive(new)
class JLToken: Repr {

    # general categories (1-31 except 10 -- 10 is reserved for newline)
    static val tEOF = 1
    static val tCOMMENT = 2
    static val tID = 3
    static val tTYPEID = 4
    static val tINT = 5
    static val tCHAR = 6
    static val tSHORT = 7
    static val tLONG = 8
    static val tDOUBLE = 9
    static val tFLOAT = 11
    static val tSTRING = 12

    # token types in the range 32-127 are restricted for ASCII single character
    # token types.

    # Multi-character symbol tokens (150-199)
    static val tPLUS_EQ = 150
    static val tMINUS_EQ = 151
    static val tSTAR_EQ = 152
    static val tREM_EQ = 153
    static val tEQ = 154
    static val tNE = 155
    static val tGE = 156
    static val tLE = 157
    static val tLSHIFT = 158
    static val tRSHIFT = 159
    static val tRSHIFTU = 160
    static val tTRUNCDIV = 161
    static val tPOWER = 162
    static val tPLUSPLUS = 163
    static val tMINUSMINUS = 164
    static val tRIGHT_ARROW = 165

    # Java keywords (200-299)
    static val kwABSTRACT = 200
    static val kwCONTINUE = 201
    static val kwFOR = 202
    static val kwNEW = 203
    static val kwSWITCH = 204
    static val kwASSERT = 205
    static val kwDEFAULT = 206
    static val kwGOTO = 207
    static val kwPACKAGE = 208
    static val kwSYNCHRONIZED = 209
    static val kwBOOLEAN = 210
    static val kwDO = 211
    static val kwIF = 212
    static val kwPRIVATE = 213
    static val kwTHIS = 214
    static val kwBREAK = 215
    static val kwDOUBLE = 216
    static val kwIMPLEMENTS = 217
    static val kwPROTECTED = 218
    static val kwTHROW = 219
    static val kwBYTE = 220
    static val kwELSE = 221
    static val kwIMPORT = 222
    static val kwPUBLIC = 223
    static val kwTHROWS = 224
    static val kwCASE = 225
    static val kwENUM = 226
    static val kwINSTANCEOF = 227
    static val kwRETURN = 228
    static val kwTRANSIENT = 229
    static val kwCATCH = 230
    static val kwEXTENDS = 231
    static val kwINT = 232
    static val kwSHORT = 233
    static val kwTRY = 234
    static val kwCHAR = 235
    static val kwFINAL = 236
    static val kwINTERFACE = 237
    static val kwSTATIC = 238
    static val kwVOID = 239
    static val kwCLASS = 240
    static val kwFINALLY = 241
    static val kwLONG = 242
    static val kwSTRICTFP = 243
    static val kwVOLATILE = 244
    static val kwCONST = 245
    static val kwFLOAT = 246
    static val kwNATIVE = 247
    static val kwSUPER = 248
    static val kwWHILE = 249

    # other keywords (300+)
    static val kwVAL = 300
    static val kwVAR = 301
    static val kwDEF = 302
    static val kwTRAIT = 303
    static val kwUNION = 304
    static val kwSTRUCT = 305
    static val kwAS = 306
    static val kwWHEN = 307
    static val kwASYNC = 308
    static val kwAWAIT = 309
    static val kwBOOL = 310
    static val kwTRUE = 311
    static val kwFALSE = 312
    static val kwNULL = 313
    static val kwYIELD = 314
    static val kwAND = 315
    static val kwOR = 316
    static val kwIS = 317
    static val kwNOT = 318
    static val kwIN = 319

    static val keywordTypes: List[Int] = [
        kwABSTRACT, kwCONTINUE, kwFOR, kwNEW, kwSWITCH, kwASSERT, kwDEFAULT, kwGOTO,
        kwPACKAGE, kwSYNCHRONIZED, kwBOOLEAN, kwDO, kwIF, kwPRIVATE, kwTHIS, kwBREAK,
        kwDOUBLE, kwIMPLEMENTS, kwPROTECTED, kwTHROW, kwBYTE, kwELSE, kwIMPORT,kwPUBLIC,
        kwTHROWS, kwCASE, kwENUM, kwINSTANCEOF, kwRETURN, kwTRANSIENT, kwCATCH, kwEXTENDS,
        kwINT, kwSHORT, kwTRY, kwCHAR, kwFINAL, kwINTERFACE, kwSTATIC, kwVOID, kwCLASS,
        kwVAL, kwFINALLY, kwLONG, kwSTRICTFP, kwVOLATILE, kwCONST, kwFLOAT, kwNATIVE,
        kwSUPER, kwWHILE, kwVAR, kwDEF, kwTRAIT, kwUNION, kwSTRUCT, kwAS, kwWHEN, kwASYNC,
        kwAWAIT, kwBOOL, kwTRUE, kwFALSE, kwNULL, kwYIELD, kwAND, kwOR, kwIS, kwNOT, kwIN]

    static val modifierKeywordTypes: Set[Int] = Set(
        kwABSTRACT, kwSYNCHRONIZED, kwPRIVATE, kwPROTECTED, kwPUBLIC, kwSTATIC, kwNATIVE,
        kwASYNC)

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
        case tPLUS_EQ = "tPLUS_EQ"
        case tMINUS_EQ = "tMINUS_EQ"
        case tSTAR_EQ = "tSTAR_EQ"
        case tREM_EQ = "tREM_EQ"
        case tEQ = "tEQ"
        case tNE = "tNE"
        case tGE = "tGE"
        case tLE = "tLE"
        case tLSHIFT = "tLSHIFT"
        case tRSHIFT = "tRSHIFT"
        case tRSHIFTU = "tRSHIFTU"
        case tTRUNCDIV = "tTRUNCDIV"
        case tPOWER = "tPOWER"
        case tPLUSPLUS = "tPLUSPLUS"
        case tMINUSMINUS = "tMINUSMINUS"
        case tRIGHT_ARROW = "tRIGHT_ARROW"
        case kwABSTRACT = "kwABSTRACT"
        case kwCONTINUE = "kwCONTINUE"
        case kwFOR = "kwFOR"
        case kwNEW = "kwNEW"
        case kwSWITCH = "kwSWITCH"
        case kwASSERT = "kwASSERT"
        case kwDEFAULT = "kwDEFAULT"
        case kwGOTO = "kwGOTO"
        case kwPACKAGE = "kwPACKAGE"
        case kwSYNCHRONIZED = "kwSYNCHRONIZED"
        case kwBOOLEAN = "kwBOOLEAN"
        case kwDO = "kwDO"
        case kwIF = "kwIF"
        case kwPRIVATE = "kwPRIVATE"
        case kwTHIS = "kwTHIS"
        case kwBREAK = "kwBREAK"
        case kwDOUBLE = "kwDOUBLE"
        case kwIMPLEMENTS = "kwIMPLEMENTS"
        case kwPROTECTED = "kwPROTECTED"
        case kwTHROW = "kwTHROW"
        case kwBYTE = "kwBYTE"
        case kwELSE = "kwELSE"
        case kwIMPORT = "kwIMPORT"
        case kwPUBLIC = "kwPUBLIC"
        case kwTHROWS = "kwTHROWS"
        case kwCASE = "kwCASE"
        case kwENUM = "kwENUM"
        case kwINSTANCEOF = "kwINSTANCEOF"
        case kwRETURN = "kwRETURN"
        case kwTRANSIENT = "kwTRANSIENT"
        case kwCATCH = "kwCATCH"
        case kwEXTENDS = "kwEXTENDS"
        case kwINT = "kwINT"
        case kwSHORT = "kwSHORT"
        case kwTRY = "kwTRY"
        case kwCHAR = "kwCHAR"
        case kwFINAL = "kwFINAL"
        case kwINTERFACE = "kwINTERFACE"
        case kwSTATIC = "kwSTATIC"
        case kwVOID = "kwVOID"
        case kwCLASS = "kwCLASS"
        case kwFINALLY = "kwFINALLY"
        case kwLONG = "kwLONG"
        case kwSTRICTFP = "kwSTRICTFP"
        case kwVOLATILE = "kwVOLATILE"
        case kwCONST = "kwCONST"
        case kwFLOAT = "kwFLOAT"
        case kwNATIVE = "kwNATIVE"
        case kwSUPER = "kwSUPER"
        case kwWHILE = "kwWHILE"
        case kwVAL = "kwVAL"
        case kwVAR = "kwVAR"
        case kwDEF = "kwDEF"
        case kwTRAIT = "kwTRAIT"
        case kwUNION = "kwUNION"
        case kwSTRUCT = "kwSTRUCT"
        case kwAS = "kwAS"
        case kwWHEN = "kwWHEN"
        case kwASYNC = "kwASYNC"
        case kwAWAIT = "kwAWAIT"
        case kwBOOL = "kwBOOL"
        case kwTRUE = "kwTRUE"
        case kwFALSE = "kwFALSE"
        case kwNULL = "kwNULL"
        case kwYIELD = "kwYIELD"
        case kwAND = "kwAND"
        case kwOR = "kwOR"
        case kwIS = "kwIS"
        case kwNOT = "kwNOT"
        case kwIN = "kwIN"
        case '\n' = "'\\n'"
        else = if type >= 32 and type <= 127 { type.toChar().repr() } else {
            "Unknown(" + type + ")"
        }
    }
}
