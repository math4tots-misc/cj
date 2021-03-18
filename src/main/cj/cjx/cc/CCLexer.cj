package cjx.cc

import cjx.parser.Mark
import cjx.cc.CCError
import cjx.re.Regex
import cjx.re.Lexer
import cjx.cc.CCToken

class CCLexer {
    private static val lexer : Lexer[CCToken] = build()

    private def build(): Lexer[CCToken] {
        val b = Lexer[CCToken].builder()
        b.add("0x[0-9A-Fa-f]+", m -> tok(m, CCToken.tINT, s -> s.parseInt().get())) # hex literals
        b.add("\\d+", m -> tok(m, CCToken.tINT, s -> s.parseInt().get()))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        b.add("==", m -> symtok(m, CCToken.tEQ))
        b.add("!=", m -> symtok(m, CCToken.tNE))
        b.add("<=", m -> symtok(m, CCToken.tLE))
        b.add(">=", m -> symtok(m, CCToken.tGE))

        # whitespace
        b.add("\\s+", m -> [])

        b.onEOF(m -> [CCToken(CCToken.tEOF, (), m.line, m.column)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw CCError("Unrecognized token", [mark])
        })

        b.build()
    }

    private def tok(
            m: Regex.MatchResult,
            type: Int,
            valf: Fn[String, CCToken.Value]): List[CCToken] = [
                CCToken(type, valf.call(m.matchText), m.line, m.column)]

    private def chartok(m: Regex.MatchResult): List[CCToken] {
        val type = m.originalString.charAt(m.start)
        [CCToken(type, (), m.line, m.column)]
    }

    private def symtok(m: Regex.MatchResult, type: Int): List[CCToken] = [
        CCToken(type, (), m.line, m.column)]

    def lex(filepath: String, string: String): List[CCToken] = lexer.lex(filepath, string)
}
