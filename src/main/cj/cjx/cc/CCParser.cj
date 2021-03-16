package cjx.cc

import cjx.cc.CCIR.Node
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

    def parseExpression(filepath: String, contents: String): Node {
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

    def expr(self): Node = exprpr(0)

    def exprpr(self, precedence: Int): Node {
        var expr = atom()
        var tokprec = precof(peek().type)
        while precedence < tokprec {
            val mark = mark()
            switch peek().type {
                case '+' { next(); expr = binop(mark, Node.Kind.add, expr, exprpr(tokprec)) }
                case '-' { next(); expr = binop(mark, Node.Kind.sub, expr, exprpr(tokprec)) }
                else = error("Unhandled operator " + peek().repr())
            }
            tokprec = precof(peek().type)
        }
        expr
    }

    def precof(type: Int): Int = switch type {
        case '+'; case '-' = 50
        else = -1
    }

    def binop(mark: CCMark, kind: Node.Kind, lhs: Node, rhs: Node): Node {
        val node = Node(mark, kind)
        node.args.add(lhs)
        node.args.add(rhs)
        node
    }

    def atom(self): Node {
        val mark = mark()
        switch peek().type {
            case '(' {
                next()
                val inner = exprpr(0)
                expect(')')
                inner
            }
            case '+' { next(); atom() }
            case '-' {
                next()
                val inner = atom()
                val expr = Node(mark, Node.Kind.neg)
                expr.args.add(inner)
                expr
            }
            case CCToken.tINT {
                val value = next().intValue
                val expr = Node(mark, Node.Kind.int)
                expr.intValue = value
                expr
            }
            else = errorKind("expression")
        }
    }
}
