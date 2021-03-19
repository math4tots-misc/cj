package cjx.notc

import cjx.parser.Mark
import cjx.re.Regex
import cjx.notc.NCError
import cjx.re.Lexer
import cjx.notc.NCToken

class NCLexer {
    private static val lexer : Lexer[NCToken] = build()

    private def build(): Lexer[NCToken] {
        val b = Lexer[NCToken].builder()
        b.add("0x[0-9A-Fa-f]+", m -> tok(m, NCToken.tINT, s -> s.parseInt().get())) # hex literals
        b.add("\\d+", m -> tok(m, NCToken.tINT, s -> s.parseInt().get()))

        for type in NCToken.keywordTypes {
            b.add(NCToken.keywordString(type), m -> symtok(m, type))
        }

        b.add("[a-z_][a-zA-Z_0-9]*", m -> tok(m, NCToken.tID, s -> s))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        b.add("==", m -> symtok(m, NCToken.tEQ))
        b.add("!=", m -> symtok(m, NCToken.tNE))
        b.add("<=", m -> symtok(m, NCToken.tLE))
        b.add(">=", m -> symtok(m, NCToken.tGE))

        # whitespace
        b.add("\\s+", m -> [])

        b.onEOF(m -> [NCToken(NCToken.tEOF, (), m.line, m.column)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw NCError("Unrecognized token", [mark])
        })

        b.build()
    }

    private def tok(
            m: Regex.MatchResult,
            type: Int,
            valf: Fn[String, NCToken.Value]): List[NCToken] = [
                NCToken(type, valf.call(m.matchText), m.line, m.column)]

    private def chartok(m: Regex.MatchResult): List[NCToken] {
        val type = m.originalString.charAt(m.start)
        [NCToken(type, (), m.line, m.column)]
    }

    private def symtok(m: Regex.MatchResult, type: Int): List[NCToken] = [
        NCToken(type, (), m.line, m.column)]

    def lex(filepath: String, string: String): List[NCToken] = lexer.lex(filepath, string)
}
