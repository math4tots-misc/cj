package cjx.lang

import cjx.lang.CJLexer
import cjx.lang.CJToken

class LexerTest {
    def lex(string: String): List[CJToken] = CJLexer.lex(string)

    @test
    def sample() {
        val tokens = lex("5")
        Assert.equal(tokens.repr(), "[CJToken(tINT, \"5\", 1, 1), CJToken(tEOF, \"\", 1, 1)]")
    }
}
