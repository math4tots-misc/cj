package cjx.cc

import cjx.cc.CCExpr
import cjx.cc.CCMark
import cjx.cc.CCError
import cjx.cc.CCLexer
import cjx.cc.CCToken
import cjx.parser.ParserMixin

class CCParser: ParserMixin[CCToken] {
    def typeOfToken(token: CCToken): Int = token.type
    def nameOfType(type: Int): String = CCToken.typeRepr(type)

    def parse(filepath: String, contents: String) {
        val tokens = CCLexer.lex(filepath, contents)
    }

    def parseExpression(filepath: String, contents: String): CCExpr {
        val tokens = CCLexer.lex(filepath, contents)
        val self = Self(filepath, tokens)
        val expr = expr()
        assert(CCToken.tEOF)
        expr
    }

    val filepath: String
    val tokens: List[CCToken]
    var i = 0

    def mark(self): CCMark = markAt(peek())
    def markAt(self, token: CCToken): CCMark = CCMark(filepath, token.line, token.column)
    def errorAt(self, message: String, token: CCToken): NoReturn = throw CCError(
        message, [markAt(token)])

    def expr(self): CCExpr = atom()

    def atom(self): CCExpr {
        val mark = mark()
        switch peek().type {
            case '(' {
                next()
                val inner = expr()
                expect(')')
                inner
            }
            case '+' { next(); atom() }
            case '-' {
                next()
                val inner = atom()
                val expr = CCExpr(mark, CCExpr.Kind.ineg)
                expr.args.add(inner)
                expr
            }
            case CCToken.tINT {
                val value = next().intValue
                val expr = CCExpr(mark, CCExpr.Kind.int)
                expr.intValue = value
                expr
            }
            else = errorKind("expression")
        }
    }
}
