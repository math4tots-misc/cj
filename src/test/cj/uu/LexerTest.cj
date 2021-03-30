package uu

import uu.UULexer
import uu.UUToken

class LexerTest {
    def lex(string: String): List[UUToken] = UULexer.lex("<test>", string)

    @test
    def sample() {
        val tokens = lex("5")
        Assert.equal(tokens.repr(), "[UUToken(tINT, \"5\", 1, 1), UUToken(tEOF, \"\", 1, 2)]")
    }

    @test
    def sample2() {
        {
            Assert.equal(
                lex("-12n").map(t -> t.repr()),
                [
                    "UUToken('-', \"\", 1, 1)",
                    "UUToken(tBIGINT, \"12n\", 1, 2)",
                    "UUToken(tEOF, \"\", 1, 5)"])
            Assert.equal(
                lex("-12n + 17 * hi\n/ Foo.bar").map(t -> t.repr()),
                [
                    "UUToken('-', \"\", 1, 1)",
                    "UUToken(tBIGINT, \"12n\", 1, 2)",
                    "UUToken('+', \"\", 1, 6)",
                    "UUToken(tINT, \"17\", 1, 8)",
                    "UUToken('*', \"\", 1, 11)",
                    "UUToken(tID, \"hi\", 1, 13)",
                    "UUToken('\\n', \"\", 1, 15)",
                    "UUToken('/', \"\", 2, 1)",
                    "UUToken(tTYPEID, \"Foo\", 2, 3)",
                    "UUToken('.', \"\", 2, 6)",
                    "UUToken(tID, \"bar\", 2, 7)",
                    "UUToken(tEOF, \"\", 2, 10)"])
        }
    }

    @test
    def keywords() {
        Assert.equal(lex("if").map(t -> t.repr()), [
            "UUToken(kwIF, \"\", 1, 1)", "UUToken(tEOF, \"\", 1, 3)"
        ])
    }

    @test
    def macroNames() {
        Assert.equal(lex("include_str!").map(t -> t.repr()), [
            "UUToken(tMACROID, \"include_str!\", 1, 1)", "UUToken(tEOF, \"\", 1, 13)"
        ])
    }
}
