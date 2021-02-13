package cjx.jl2

import cj.StringBuilder
import cjx.jl1.JLError
import cjx.jl1.JLMark
import cjx.jl2.JLMetaVal
import cjx.jl1.JLToken
import cjx.jl1.JLLexer
import cjx.jl2.JLMetaExpr

@derive(new)
class JLMetaParser {

    def parse(filename: String, string: String): JLMetaExpr {
        val tokens = JLLexer.lex(filename, string)
        val parser = Self(filename, tokens)
        parser.parseFile()
    }

    val filename: String
    val tokens: List[JLToken]
    var i = 0

    private def __get_mark(self): JLMark = peek().toMark(filename)
    private def peek(self): JLToken = tokens[i]
    private def next(self): JLToken = {
        val token = tokens[i]
        i = i + 1
        token
    }
    private def at(self, type: Int): Bool = peek().type == type
    private def atOffset(self, type: Int, offset: Int): Bool = {
        val j = i + offset
        j < tokens.size() and tokens[j].type == type
    }
    private def expect(self, type: Int): JLToken {
        if not at(type) {
            throw JLError(
                "Expected " + JLToken.typeRepr(type) + " but got " +
                JLToken.typeRepr(peek().type),
                [mark])
        }
        next()
    }
    private def consume(self, type: Int): Bool = if at(type) { next(); true } else { false }

    private def parseInt(self): Double = translateInt(
        mark, expect(JLToken.tINT).text)

    private def parseDouble(self): Double = translateDouble(
        mark, expect(JLToken.tDOUBLE).text)

    private def parseString(self): String = translateStringLiteral(
        mark, expect(JLToken.tSTRING).text)

    private def parseId(self): String {
        expect(JLToken.tID).text
    }

    private def parseIdEx(self): String {
        switch peek().type {
            case (JLToken.kwIF)
            case (JLToken.kwELSE)
            case (JLToken.kwWHILE)
            case (JLToken.kwVAR)
            case (JLToken.kwVAL)
            case (JLToken.kwFALSE)
            case (JLToken.kwTRUE) = JLToken.keywordString(next().type)
            else = parseId()
        }
    }

    private def parseTypeId(self): String {
        expect(JLToken.tTYPEID).text
    }

    private def skipDelimiters(self) {
        while at('\n') or at(';') {
            next()
        }
    }

    private def translateInt(mark: JLMark, input: String): Int {
        if null(i) = input.parseInt() {
            i
        } else {
            throw JLError("Unrecognized int literal " + input, [mark])
        }
    }

    private def translateDouble(mark: JLMark, input: String): Double {
        if null(f) = input.parseDouble() {
            f
        } else {
            throw JLError("Unrecognized double literal " + input, [mark])
        }
    }

    private def translateStringLiteral(mark: JLMark, input: String): String {
        val sb = StringBuilder()
        Assert.equal(input.charAt(0), '"')
        Assert.equal(input.charAt(input.size() - 1), '"')
        var i = 1
        while i + 1 < input.size() {
            switch input.charAt(i) {
                case '\\' = {
                    i++
                    sb.add(switch input.charAt(i) {
                        case 'n' = "\n"
                        case 't' = "\t"
                        case '\'' = "\'"
                        case '"' = "\""
                        else = throw JLError(
                            "Unrecognized escape: " + input.charAt(i).repr(), [mark])
                    })
                }
                else = sb.add(input.charAt(i).toString())
            }
            i += input.charAt(i).size()
        }
        sb.toString()
    }

    private def expectDelimiters(self) {
        if not (at('\n') or at(';') or at('}') or at(JLToken.tEOF)) {
            throw JLError("Expected delimiter", [mark])
        }
        skipDelimiters()
    }

    private def parseFile(self): JLMetaExpr {
        val mark = mark
        val exprs: List[JLMetaExpr] = []
        skipDelimiters()
        while not at(JLToken.tEOF) {
            exprs.add(parseExpr())
            skipDelimiters()
        }
        JLMetaExpr(mark, JLMetaExpr.Data.apply("module", exprs))
    }

    private def parseExpr(self): JLMetaExpr {
        val mark = mark
        switch peek().type {
            case '(' = {
                next()
                val form = parseIdEx()
                val args: List[JLMetaExpr] = []
                while not consume(')') {
                    args.add(parseExpr())
                }
                JLMetaExpr(mark, JLMetaExpr.Data.apply(form, args))
            }
            case '[' = {
                next()
                val args: List[JLMetaExpr] = []
                while not consume(']') {
                    args.add(parseExpr())
                }
                JLMetaExpr(mark, JLMetaExpr.Data.apply("list", args))
            }
            case (JLToken.kwTRUE) = JLMetaExpr(
                mark, JLMetaExpr.Data.literal(JLMetaVal.bool(true)))
            case (JLToken.kwFALSE) = JLMetaExpr(
                mark, JLMetaExpr.Data.literal(JLMetaVal.bool(false)))
            case (JLToken.tINT) = JLMetaExpr(
                mark, JLMetaExpr.Data.literal(JLMetaVal.number(parseInt())))
            case (JLToken.tDOUBLE) = JLMetaExpr(
                mark, JLMetaExpr.Data.literal(JLMetaVal.number(parseDouble())))
            case (JLToken.tSTRING) = JLMetaExpr(
                mark, JLMetaExpr.Data.literal(JLMetaVal.string(parseString())))
            case (JLToken.kwVAR)
            case (JLToken.kwVAL) = JLMetaExpr(
                mark, JLMetaExpr.Data.name(JLToken.keywordString(next().type)))
            case (JLToken.tID) = {
                val name = parseId()
                switch name {
                    case "nil" = JLMetaExpr(mark, JLMetaExpr.Data.literal(JLMetaVal.nil()))
                    else = JLMetaExpr(mark, JLMetaExpr.Data.name(name))
                }
            }
            else = throw JLError("Expected expression", [mark])
        }
    }
}
