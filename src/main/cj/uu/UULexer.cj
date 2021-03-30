package uu

import cjx.parser.MError
import cjx.parser.Mark
import cjx.re.Lexer
import uu.UUToken
import cjx.re.Regex


class UULexer {
    private static val lexer : Lexer[UUToken] = build()

    private def build() : Lexer[UUToken] {
        val b = Lexer[UUToken].builder()
        b.add("(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?", m -> tok(UUToken.tDOUBLE, m))
        b.add("\\d+(e|E)-?\\d+", m -> tok(UUToken.tDOUBLE, m))
        b.add("0x[0-9A-Fa-f]+n", m -> tok(UUToken.tBIGINT, m)) # hex literals
        b.add("\\d+n", m -> tok(UUToken.tBIGINT, m))
        b.add("0x[0-9A-Fa-f]+", m -> tok(UUToken.tINT, m)) # hex literals
        b.add("\\d+", m -> tok(UUToken.tINT, m))
        for type in UUToken.keywordTypes {
            b.add(UUToken.keywordString(type), m -> symtok(type, m))
        }
        b.add("[A-Z]\\w*", m -> tok(UUToken.tTYPEID, m))
        b.add("[a-z_]\\w*", m -> tok(UUToken.tID, m))
        b.add("[a-z_]\\w*!", m -> tok(UUToken.tMACROID, m))
        b.add("'\\\\.'", m -> tok(UUToken.tCHAR, m))
        b.add("'[^'\\\\]'", m -> tok(UUToken.tCHAR, m))
        b.add("\"(\\\\.|[^\"\\\\])*\"", m -> tok(UUToken.tSTRING, m))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        # multi-character symbol tokens
        b.add("\\.\\.", m -> symtok(UUToken.tDOTDOT, m))
        b.add("==", m -> symtok(UUToken.tEQ, m))
        b.add("!=", m -> symtok(UUToken.tNE, m))
        b.add("<=", m -> symtok(UUToken.tLE, m))
        b.add(">=", m -> symtok(UUToken.tGE, m))
        b.add("<<", m -> symtok(UUToken.tLSHIFT, m))
        b.add(">>", m -> symtok(UUToken.tRSHIFT, m))
        b.add(">>>", m -> symtok(UUToken.tRSHIFTU, m))
        b.add("//", m -> symtok(UUToken.tTRUNCDIV, m))
        b.add("->", m -> symtok(UUToken.tRIGHT_ARROW, m))
        b.add("\\*\\*", m -> symtok(UUToken.tPOWER, m))
        b.add("\\+\\+", m -> symtok(UUToken.tPLUSPLUS, m))
        b.add("--", m -> symtok(UUToken.tMINUSMINUS, m))
        b.add("\\+=", m -> symtok(UUToken.tPLUS_EQ, m))
        b.add("-=", m -> symtok(UUToken.tMINUS_EQ, m))
        b.add("\\*=", m -> symtok(UUToken.tSTAR_EQ, m))
        b.add("%=", m -> symtok(UUToken.tREM_EQ, m))

        # newline
        b.add("\n\\s*", m -> chartok(m))

        # comments
        b.add("##[^\n]*(\n\\s*##[^\n]*)*", m -> tok(UUToken.tCOMMENT, m))
        b.add("#[^\n]*(\n\\s*#[^\n]*)*", m -> [])

        # whitespace
        b.add("[^\\S\n]+", m -> [])

        b.onEOF(m -> [UUToken(UUToken.tEOF, "", m.line, m.column)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw MError("Unrecognized token", [mark])
        })

        b.build()
    }

    private def tok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type, m.matchText, m.line, m.column)]

    private def chartok(m: Regex.MatchResult): List[UUToken] = {
        val type = m.originalString.charAt(m.start)
        [UUToken(type, "", m.line, m.column)]
    }

    private def symtok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type, "", m.line, m.column)]

    def lex(filename: String, string: String): List[UUToken] = {
        val oldTokens = lexer.lex(filename, string)
        val newTokens = List[UUToken].empty()
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
