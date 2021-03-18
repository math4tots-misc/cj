package cjx.cc

import cjx.parser.Mark
import cjx.cc.CCIR.Node
import cjx.cc.CCIR.Obj
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

    def parseStatements(filepath: String, contents: String): List[Node] {
        val tokens = CCLexer.lex(filepath, contents)
        val self = Self(filepath, tokens)
        val stmts: List[Node] = []
        while not at(CCToken.tEOF) {
            stmts.add(stmt())
        }
        stmts
    }

    val filepath: String
    val tokens: List[CCToken]
    var i = 0

    val varMap: Map[String, Obj] = MapOf()

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: CCToken): Mark = Mark(filepath, token.line, token.column)
    def errorAt(self, message: String, token: CCToken): NoReturn = throw CCError(
        message, [markAt(token)])

    def stmt(self): Node {
        val mark = mark()
        switch (peek().type) {
            case ';' {
                next()
                val node = Node(mark, Node.Kind.block)
                node.body = []
                node
            }
            case CCToken.kwRETURN {
                next()
                val stmt = unop(mark, Node.Kind.return_, expr())
                expect(';')
                stmt
            }
            case '{' = block()
            else {
                val stmt = unop(mark, Node.Kind.exprStmt, expr())
                expect(';')
                stmt
            }
        }
    }

    def expr(self): Node = exprpr(0)

    def exprpr(self, precedence: Int): Node {
        var expr = atom()
        var tokprec = precof(peek().type)
        while precedence < tokprec {
            val mark = mark()
            switch peek().type {
                case '+'         { next(); expr = binop(mark, Node.Kind.add, expr, exprpr(tokprec)) }
                case '-'         { next(); expr = binop(mark, Node.Kind.sub, expr, exprpr(tokprec)) }
                case '*'         { next(); expr = binop(mark, Node.Kind.mul, expr, exprpr(tokprec)) }
                case '/'         { next(); expr = binop(mark, Node.Kind.div, expr, exprpr(tokprec)) }
                case '%'         { next(); expr = binop(mark, Node.Kind.rem, expr, exprpr(tokprec)) }
                case CCToken.tEQ { next(); expr = binop(mark, Node.Kind.eq, expr, exprpr(tokprec)) }
                case CCToken.tNE { next(); expr = binop(mark, Node.Kind.ne, expr, exprpr(tokprec)) }
                case '<'         { next(); expr = binop(mark, Node.Kind.lt, expr, exprpr(tokprec)) }
                case CCToken.tLE { next(); expr = binop(mark, Node.Kind.le, expr, exprpr(tokprec)) }
                case '>'         { next(); expr = binop(mark, Node.Kind.lt, exprpr(tokprec), expr) }
                case CCToken.tGE { next(); expr = binop(mark, Node.Kind.le, exprpr(tokprec), expr) }
                case '='         { next(); expr = binop(mark, Node.Kind.assign, expr, exprpr(tokprec - 1)) }
                else = error("Unhandled operator " + peek().repr())
            }
            tokprec = precof(peek().type)
        }
        expr
    }

    def precof(type: Int): Int = switch type {
        case '*'; case '/'; case '%' = 120
        case '+'; case '-' = 100
        case '<'; case '>'; case CCToken.tLE; case CCToken.tGE = 80
        case CCToken.tEQ; case CCToken.tNE = 70
        case '=' = 50
        else = -1
    }

    def binop(mark: Mark, kind: Node.Kind, lhs: Node, rhs: Node): Node {
        val node = Node(mark, kind)
        node.lhs = lhs
        node.rhs = rhs
        node
    }

    def unop(mark: Mark, kind: Node.Kind, arg: Node): Node {
        val node = Node(mark, kind)
        node.arg = arg
        node
    }

    def literal(mark: Mark, kind: Node.Kind, value: Node.Value): Node {
        val node = Node(mark, kind)
        node.value = value
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
            case '+' { next(); unop(mark, Node.Kind.pos, atom()) }
            case '-' { next(); unop(mark, Node.Kind.neg, atom()) }
            case CCToken.tINT { literal(mark, Node.Kind.int, next().intValue) }
            case CCToken.tIDENT {
                val name = next().stringValue
                val var_ = varMap.getOrInsert(name, () -> Obj(name, varMap.size()))
                val node = Node(mark, Node.Kind.var_)
                node.var_ = var_
                node
            }
            else = errorKind("expression")
        }
    }

    def block(self): Node {
        val mark = mark()
        val body: List[Node] = []
        expect('{')
        while not consume('}') {
            body.add(stmt())
        }
        val node = Node(mark, Node.Kind.block)
        node.body = body
        node
    }
}
