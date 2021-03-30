package uu

import cj.BigInt
import cjx.parser.MError
import cjx.parser.Mark
import cjx.re.Lexer
import uu.UUToken
import cjx.re.Regex


class UULexer {
    private static val lexer : Lexer[UUToken] = build()

    private def build() : Lexer[UUToken] {
        val b = Lexer[UUToken].builder()
        b.add("(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?", m -> dtok(UUToken.tDOUBLE, m))
        b.add("\\d+(e|E)-?\\d+", m -> dtok(UUToken.tDOUBLE, m))
        b.add("0x[0-9A-Fa-f]+n", m -> bitok(UUToken.tBIGINT, m)) # hex literals
        b.add("\\d+n", m -> bitok(UUToken.tBIGINT, m))
        b.add("0x[0-9A-Fa-f]+", m -> itok(UUToken.tINT, m)) # hex literals
        b.add("\\d+", m -> itok(UUToken.tINT, m))
        for type in UUToken.keywordTypes {
            b.add(UUToken.keywordString(type), m -> symtok(type, m))
        }
        b.add("[A-Z]\\w*", m -> ntok(UUToken.tTYPEID, m))
        b.add("[a-z_]\\w*", m -> ntok(UUToken.tID, m))
        b.add("[a-z_]\\w*!", m -> ntok(UUToken.tMACROID, m))
        b.add("'\\\\.'", m -> cltok(UUToken.tCHAR, m))
        b.add("'[^'\\\\]'", m -> cltok(UUToken.tCHAR, m))
        b.add("\"(\\\\.|[^\"\\\\])*\"", m -> sltok(UUToken.tSTRING, m))

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
        b.add("##[^\n]*(\n\\s*##[^\n]*)*", m -> ntok(UUToken.tCOMMENT, m))
        b.add("#[^\n]*(\n\\s*#[^\n]*)*", m -> [])

        # whitespace
        b.add("[^\\S\n]+", m -> [])

        b.onEOF(m -> [UUToken(UUToken.tEOF, UUToken.Value.none, m.line, m.column, m.filename)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw MError("Unrecognized token", [mark])
        })

        b.build()
    }

    private def itok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type, UUToken.Value.int(Int(m.matchText)), m.line, m.column, m.filename)]

    private def bitok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type,
            UUToken.Value.bigInt(BigInt(m.matchText.rstripChar('n'))),
            m.line,
            m.column,
            m.filename)]

    private def dtok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type, UUToken.Value.double(Double(m.matchText)), m.line, m.column, m.filename)]

    ## 'name' token -- save the token match text as is
    private def ntok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type, UUToken.Value.string(m.matchText), m.line, m.column, m.filename)]

    ## string literal token
    private def sltok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type, UUToken.Value.string(m.matchText.unrepr()), m.line, m.column, m.filename)]

    ## char literal token
    private def cltok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type, UUToken.Value.char(m.matchText.unreprChar()), m.line, m.column, m.filename)]

    private def chartok(m: Regex.MatchResult): List[UUToken] = {
        val type = m.originalString.charAt(m.start)
        [UUToken(type, UUToken.Value.none, m.line, m.column, m.filename)]
    }

    private def symtok(type: Int, m: Regex.MatchResult): List[UUToken] = [
        UUToken(type, UUToken.Value.none, m.line, m.column, m.filename)]

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
