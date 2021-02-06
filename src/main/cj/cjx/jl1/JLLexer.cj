package cjx.jl1

import cjx.jl1.JLError
import cjx.jl1.JLMark
import cjx.re.Regex
import cjx.re.Lexer
import cjx.jl1.JLToken

class JLLexer {

    def lex(filename: String, string: String): List[JLToken] = lexer.lex(filename, string)

    private static val lexer: Lexer[JLToken] = build()

    private def build(): Lexer[JLToken] {
        val b = Lexer[JLToken].builder()

        b.add("(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?", m -> tok(JLToken.tDOUBLE, m))
        b.add("\\d+(e|E)-?\\d+", m -> tok(JLToken.tDOUBLE, m))
        b.add("0x[0-9A-Fa-f]+", m -> tok(JLToken.tINT, m)) # hex literals
        b.add("\\d+", m -> tok(JLToken.tINT, m))
        for type in JLToken.keywordTypes {
            b.add(JLToken.keywordString(type), m -> symtok(type, m))
        }
        b.add("[A-Z]\\w*", m -> tok(JLToken.tTYPEID, m))
        b.add("[a-z_]\\w*", m -> tok(JLToken.tID, m))
        b.add("'\\\\.'", m -> tok(JLToken.tCHAR, m))
        b.add("'[^'\\\\]'", m -> tok(JLToken.tCHAR, m))
        b.add("\"(\\\\.|[^\"\\\\])*\"", m -> tok(JLToken.tSTRING, m))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        # newline
        b.add("\n\\s*", m -> chartok(m))

        # comments
        b.add("##[^\n]*(\n\\s*##[^\n]*)*", m -> tok(JLToken.tCOMMENT, m))
        b.add("#[^\n]*(\n\\s*#[^\n]*)*", m -> [])

        # whitespace
        b.add("[^\\S\n]+", m -> [])

        b.onEOF(m -> [JLToken(JLToken.tEOF, "", m.line, m.column)])
        b.onError(m ->
            throw JLError("Unrecognized token", [JLMark(m.filename, m.line, m.column)]))
        b.build()
    }

    private def tok(type: Int, m: Regex.MatchResult): List[JLToken] = [
        JLToken(type, m.matchText, m.line, m.column)]

    private def chartok(m: Regex.MatchResult): List[JLToken] = {
        val type = m.originalString.charAt(m.start)
        [JLToken(type, "", m.line, m.column)]
    }

    private def symtok(type: Int, m: Regex.MatchResult): List[JLToken] = [
        JLToken(type, "", m.line, m.column)]
}
