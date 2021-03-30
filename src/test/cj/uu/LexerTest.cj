package uu

import uu.UULexer
import uu.UUToken

class LexerTest {
    def lex(string: String): List[UUToken] = UULexer.lex("<test>", string)

    @test
    def sample() {
        val tokens = lex("5")
        Assert.equal(tokens.repr(), "[UUToken(tINT, 5, 1, 1), UUToken(tEOF, none, 1, 2)]")
    }

    @test
    def sample2() {
        {
            Assert.equal(
                lex("-12n").map(t -> t.repr()),
                [
                    "UUToken('-', none, 1, 1)",
                    "UUToken(tBIGINT, 12n, 1, 2)",
                    "UUToken(tEOF, none, 1, 5)"])
            Assert.equal(
                lex("-12n + 17 * hi\n/ Foo.bar").map(t -> t.repr()),
                [
                    "UUToken('-', none, 1, 1)",
                    "UUToken(tBIGINT, 12n, 1, 2)",
                    "UUToken('+', none, 1, 6)",
                    "UUToken(tINT, 17, 1, 8)",
                    "UUToken('*', none, 1, 11)",
                    "UUToken(tID, \"hi\", 1, 13)",
                    "UUToken('\\n', none, 1, 15)",
                    "UUToken('/', none, 2, 1)",
                    "UUToken(tTYPEID, \"Foo\", 2, 3)",
                    "UUToken('.', none, 2, 6)",
                    "UUToken(tID, \"bar\", 2, 7)",
                    "UUToken(tEOF, none, 2, 10)"])
        }
    }

    @test
    def keywords() {
        Assert.equal(lex("if").map(t -> t.repr()), [
            "UUToken(kwIF, none, 1, 1)", "UUToken(tEOF, none, 1, 3)"
        ])
    }

    @test
    def macroNames() {
        Assert.equal(lex("include_str!").map(t -> t.repr()), [
            "UUToken(tMACROID, \"include_str!\", 1, 1)", "UUToken(tEOF, none, 1, 13)"
        ])
    }
}
