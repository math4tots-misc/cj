package compiler

import compiler.CJError
import cjx.parser.Mark
import cjx.re.Lexer
import compiler.CJToken
import cjx.re.Regex


class CJLexer {
    private static val lexer : Lexer[CJToken] = build()

    private def build() : Lexer[CJToken] {
        val b = Lexer[CJToken].builder()
        b.add("(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?", m -> tok(CJToken.tDOUBLE, m))
        b.add("\\d+(e|E)-?\\d+", m -> tok(CJToken.tDOUBLE, m))
        b.add("0x[0-9A-Fa-f]+n", m -> tok(CJToken.tBIGINT, m)) # hex literals
        b.add("\\d+n", m -> tok(CJToken.tBIGINT, m))
        b.add("0x[0-9A-Fa-f]+", m -> tok(CJToken.tINT, m)) # hex literals
        b.add("\\d+", m -> tok(CJToken.tINT, m))
        for type in CJToken.keywordTypes {
            b.add(CJToken.keywordString(type), m -> symtok(type, m))
        }
        b.add("[A-Z]\\w*", m -> tok(CJToken.tTYPEID, m))
        b.add("[a-z_]\\w*", m -> tok(CJToken.tID, m))
        b.add("[a-z_]\\w*!", m -> tok(CJToken.tMACROID, m))
        b.add("'\\\\.'", m -> tok(CJToken.tCHAR, m))
        b.add("'[^'\\\\]'", m -> tok(CJToken.tCHAR, m))
        b.add("\"(\\\\.|[^\"\\\\])*\"", m -> tok(CJToken.tSTRING, m))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        # multi-character symbol tokens
        b.add("\\.\\.", m -> symtok(CJToken.tDOTDOT, m))
        b.add("==", m -> symtok(CJToken.tEQ, m))
        b.add("!=", m -> symtok(CJToken.tNE, m))
        b.add("<=", m -> symtok(CJToken.tLE, m))
        b.add(">=", m -> symtok(CJToken.tGE, m))
        b.add("<<", m -> symtok(CJToken.tLSHIFT, m))
        b.add(">>", m -> symtok(CJToken.tRSHIFT, m))
        b.add(">>>", m -> symtok(CJToken.tRSHIFTU, m))
        b.add("//", m -> symtok(CJToken.tTRUNCDIV, m))
        b.add("->", m -> symtok(CJToken.tRIGHT_ARROW, m))
        b.add("\\*\\*", m -> symtok(CJToken.tPOWER, m))
        b.add("\\+\\+", m -> symtok(CJToken.tPLUSPLUS, m))
        b.add("--", m -> symtok(CJToken.tMINUSMINUS, m))
        b.add("\\+=", m -> symtok(CJToken.tPLUS_EQ, m))
        b.add("-=", m -> symtok(CJToken.tMINUS_EQ, m))
        b.add("\\*=", m -> symtok(CJToken.tSTAR_EQ, m))
        b.add("%=", m -> symtok(CJToken.tREM_EQ, m))

        # newline
        b.add("\n\\s*", m -> chartok(m))

        # comments
        b.add("##[^\n]*(\n\\s*##[^\n]*)*", m -> tok(CJToken.tCOMMENT, m))
        b.add("#[^\n]*(\n\\s*#[^\n]*)*", m -> [])

        # whitespace
        b.add("[^\\S\n]+", m -> [])

        b.onEOF(m -> [CJToken(CJToken.tEOF, "", m.line, m.column)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw CJError("Unrecognized token", [mark])
        })

        b.build()
    }

    private def tok(type: Int, m: Regex.MatchResult): List[CJToken] = [
        CJToken(type, m.matchText, m.line, m.column)]

    private def chartok(m: Regex.MatchResult): List[CJToken] = {
        val type = m.originalString.charAt(m.start)
        [CJToken(type, "", m.line, m.column)]
    }

    private def symtok(type: Int, m: Regex.MatchResult): List[CJToken] = [
        CJToken(type, "", m.line, m.column)]

    def lex(filename: String, string: String): List[CJToken] = {
        val oldTokens = lexer.lex(filename, string)
        val newTokens = List[CJToken].empty()
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
