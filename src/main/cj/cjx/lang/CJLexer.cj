package cjx.lang

import cjx.re.Lexer
import cjx.lang.CJToken
import cjx.re.Regex


class CJLexer {
    private static val lexer : Lexer[CJToken] = build()

    private def build() : Lexer[CJToken] {
        val b = Lexer[CJToken].builder()
        b.add("(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?", m -> tok(CJToken.tDOUBLE, m))
        b.add("\\d+(e|E)-?\\d+", m -> tok(CJToken.tDOUBLE, m));
        b.add("\\d+n", m -> tok(CJToken.tBIGINT, m));
        b.add("0x[0-9A-Fa-f]+", m -> tok(CJToken.tINT, m)); # hex literals
        b.add("\\d+", m -> tok(CJToken.tINT, m));
        for type in CJToken.keywordTypes {
            b.add(CJToken.keywordString(type), m -> tok(type, m))
        }
        b.build()
    }

    private def tok(type: Int, m: Regex.MatchResult): List[CJToken] = [
        CJToken(type, m.matchText, m.line, m.column)]

    def lex(string: String): List[CJToken] = {
        val tokens = lexer.lex(string)
        tokens.add(CJToken(CJToken.tEOF, "", 1, 1))
        tokens
    }
}
