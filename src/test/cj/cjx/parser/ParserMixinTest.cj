package cjx.parser

import cj.Error
import cjx.parser.ParserMixin

class ParserMixinTest {

    union Expr: Repr {
        case digit(Int)
        case list(List[Expr])

        def repr(self): String = when self {
            else name(x) = name + "(" + x.repr() + ")"
        }
    }

    class Parser : ParserMixin[Char] {
        static val tDIGIT: Int = -1

        def typeOfToken(ch: Char): Int = if ch.isDigit() { tDIGIT } else { ch.toInt() }
        def nameOfType(type: Int): String = switch type {
            case tDIGIT = "DIGIT"
            else = type.toChar().repr()
        }

        val filepath = "<test>"
        val tokens: List[Char]
        var i = 0

        def errorAt(self, message: String, token: Char): NoReturn = throw Error(message)

        def parse(self): Expr {
            val expr = parseExpr()
            if i < tokens.size() {
                error("Expected EOF")
            }
            expr
        }

        def parseExpr(self): Expr {
            if at(tDIGIT) {
                Expr.digit(next().toChar().toString().parseInt().get())
            } else {
                Expr.list(parseJoin('[', ']', ',', () -> parseExpr()))
            }
        }
    }

    def parse(string: String): Expr = Parser(string.iter().toList()).parse()

    @test
    def sampleParser() {
        Assert.equal(parse("[1,2,3]").repr(), "list([digit(1), digit(2), digit(3)])")
    }
}
