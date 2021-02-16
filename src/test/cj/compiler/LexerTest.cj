package compiler

import compiler.CJLexer
import compiler.CJToken

class LexerTest {
    def lex(string: String): List[CJToken] = CJLexer.lex("<test>", string)

    @test
    def sample() {
        val tokens = lex("5")
        Assert.equal(tokens.repr(), "[CJToken(tINT, \"5\", 1, 1), CJToken(tEOF, \"\", 1, 2)]")
    }

    @test
    def sample2() {
        {
            Assert.equal(
                lex("-12n").map(t -> t.repr()),
                [
                    "CJToken('-', \"\", 1, 1)",
                    "CJToken(tBIGINT, \"12n\", 1, 2)",
                    "CJToken(tEOF, \"\", 1, 5)"])
            Assert.equal(
                lex("-12n + 17 * hi\n/ Foo.bar").map(t -> t.repr()),
                [
                    "CJToken('-', \"\", 1, 1)",
                    "CJToken(tBIGINT, \"12n\", 1, 2)",
                    "CJToken('+', \"\", 1, 6)",
                    "CJToken(tINT, \"17\", 1, 8)",
                    "CJToken('*', \"\", 1, 11)",
                    "CJToken(tID, \"hi\", 1, 13)",
                    "CJToken('\\n', \"\", 1, 15)",
                    "CJToken('/', \"\", 2, 1)",
                    "CJToken(tTYPEID, \"Foo\", 2, 3)",
                    "CJToken('.', \"\", 2, 6)",
                    "CJToken(tID, \"bar\", 2, 7)",
                    "CJToken(tEOF, \"\", 2, 10)"])
        }
    }

    @test
    def keywords() {
        Assert.equal(lex("if").map(t -> t.repr()), [
            "CJToken(kwIF, \"\", 1, 1)", "CJToken(tEOF, \"\", 1, 3)"
        ])
    }
}
