package cjx.cx

import cjx.re.Lexer
import cjx.parser.MError
import cjx.parser.Mark
import cjx.re.Regex
import cjx.cx.CXToken

class CXLexer {
    private static val lexer : Lexer[CXToken] = build()

    private def build() : Lexer[CXToken] {
        val b = Lexer[CXToken].builder()
        b.add("(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?", m -> tok(CXToken.tDOUBLE, m))
        b.add("\\d+(e|E)-?\\d+", m -> tok(CXToken.tDOUBLE, m))
        b.add("0x[0-9A-Fa-f]+n", m -> tok(CXToken.tBIGINT, m)) # hex literals
        b.add("\\d+n", m -> tok(CXToken.tBIGINT, m))
        b.add("0x[0-9A-Fa-f]+", m -> tok(CXToken.tINT, m)) # hex literals
        b.add("\\d+", m -> tok(CXToken.tINT, m))
        for type in CXToken.keywordTypes {
            b.add(CXToken.keywordString(type), m -> symtok(type, m))
        }
        b.add("[A-Z]\\w*", m -> tok(CXToken.tTYPEID, m))
        b.add("[a-z_]\\w*", m -> tok(CXToken.tID, m))
        b.add("[a-z_]\\w*!", m -> tok(CXToken.tMACROID, m))
        b.add("'\\\\.'", m -> tok(CXToken.tCHAR, m))
        b.add("'[^'\\\\]'", m -> tok(CXToken.tCHAR, m))
        b.add("\"(\\\\.|[^\"\\\\])*\"", m -> tok(CXToken.tSTRING, m))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        # multi-character symbol tokens
        b.add("\\.\\.", m -> symtok(CXToken.tDOTDOT, m))
        b.add("==", m -> symtok(CXToken.tEQ, m))
        b.add("!=", m -> symtok(CXToken.tNE, m))
        b.add("<=", m -> symtok(CXToken.tLE, m))
        b.add(">=", m -> symtok(CXToken.tGE, m))
        b.add("<<", m -> symtok(CXToken.tLSHIFT, m))
        b.add(">>", m -> symtok(CXToken.tRSHIFT, m))
        b.add(">>>", m -> symtok(CXToken.tRSHIFTU, m))
        b.add("//", m -> symtok(CXToken.tTRUNCDIV, m))
        b.add("->", m -> symtok(CXToken.tRIGHT_ARROW, m))
        b.add("\\*\\*", m -> symtok(CXToken.tPOWER, m))
        b.add("\\+\\+", m -> symtok(CXToken.tPLUSPLUS, m))
        b.add("--", m -> symtok(CXToken.tMINUSMINUS, m))
        b.add("\\+=", m -> symtok(CXToken.tPLUS_EQ, m))
        b.add("-=", m -> symtok(CXToken.tMINUS_EQ, m))
        b.add("\\*=", m -> symtok(CXToken.tSTAR_EQ, m))
        b.add("%=", m -> symtok(CXToken.tREM_EQ, m))

        # newline
        b.add("\n\\s*", m -> chartok(m))

        # comments
        b.add("##[^\n]*(\n\\s*##[^\n]*)*", m -> tok(CXToken.tCOMMENT, m))
        b.add("#[^\n]*(\n\\s*#[^\n]*)*", m -> [])

        # whitespace
        b.add("[^\\S\n]+", m -> [])

        b.onEOF(m -> [CXToken(CXToken.tEOF, "", m.line, m.column)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw MError("Unrecognized token", [mark])
        })

        b.build()
    }

    private def tok(type: Int, m: Regex.MatchResult): List[CXToken] = [
        CXToken(type, m.matchText, m.line, m.column)]

    private def chartok(m: Regex.MatchResult): List[CXToken] = {
        val type = m.originalString.charAt(m.start)
        [CXToken(type, "", m.line, m.column)]
    }

    private def symtok(type: Int, m: Regex.MatchResult): List[CXToken] = [
        CXToken(type, "", m.line, m.column)]

    def lex(filename: String, string: String): List[CXToken] = {
        val oldTokens = lexer.lex(filename, string)
        val newTokens = List[CXToken].empty()
        val stack = List[Int].empty()
        for token in oldTokens {
            switch token.type {
                case '('
                case '['
                case '{' = {
                    stack.add(token.type)
                    newTokens.add(token)
                }
                case ')'
                case '}'
                case ']' = {
                    if stack {
                        stack.pop()
                    }
                    newTokens.add(token)
                }
                case '\n' = if not stack or stack.last() == '{' {
                    newTokens.add(token)
                }
                else = newTokens.add(token)
            }
        }
        newTokens
    }
}
