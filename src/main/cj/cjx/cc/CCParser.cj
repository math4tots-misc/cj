package cjx.cc

import cjx.cc.CCLocals
import cjx.cc.CCType
import cjx.parser.Mark
import cjx.cc.CCIR
import cjx.cc.CCIR.Node
import cjx.cc.CCIR.Type
import cjx.cc.CCIR.Obj
import cjx.cc.CCError
import cjx.cc.CCLexer
import cjx.cc.CCToken
import cjx.parser.ParserMixin

class CCParser: ParserMixin[CCToken] {
    static private val unaryPrec: Int = precof('*') + 5

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
    var locals: CCLocals = CCLocals()

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: CCToken): Mark = Mark(filepath, token.line, token.column)
    def errorAt(self, message: String, token: CCToken): NoReturn = throw CCError(
        message, [markAt(token)])
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw CCError(
        message, [mark])

    def stmt(self): Node {
        val mark = mark()
        switch (peek().type) {
            case ';' {
                next()
                nop(mark)
            }
            case CCToken.kwRETURN {
                next()
                val stmt = unop(mark, Node.Kind.return_, expr())
                expect(';')
                stmt
            }
            case CCToken.kwIF {
                next()
                val stmt = Node(mark, Node.Kind.if_)
                expect('(')
                stmt.cond = expr()
                expect(')')
                stmt.then = stmt()
                stmt.els = if consume(CCToken.kwELSE) { stmt() } else { nop(mark) }
                stmt
            }
            case CCToken.kwFOR {
                next()
                expect('(')
                val stmt = Node(mark, Node.Kind.for_)
                stmt.init = stmt()
                stmt.cond = if at(';') { intNode(mark, 1) } else { expr() }
                expect(';')
                stmt.inc = if at(')') { intNode(mark, 0) } else { expr() }
                expect(')')
                stmt.then = stmt()
                stmt
            }
            case CCToken.kwWHILE {
                next()
                expect('(')
                val stmt = Node(mark, Node.Kind.for_)
                stmt.init = nop(mark)
                stmt.cond = expr()
                expect(')')
                stmt.inc = intNode(mark, 0)
                stmt.then = stmt()
                stmt
            }
            case '{' = block()
            else {
                val stmt = exprStmtNode(expr())
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
                case '+'         { next(); expr = newadd(mark, expr, exprpr(tokprec)) }
                case '-'         { next(); expr = newsub(mark, expr, exprpr(tokprec)) }
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

    def newadd(self, mark: Mark, var lhs: Node, var rhs: Node): Node {
        CCType.addType(lhs)
        CCType.addType(rhs)

        # 'int + int' goes through as is
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Node.Kind.add, lhs, rhs)
        }

        # 'num + ptr' -> 'ptr + num'
        if lhs.type.isInt() and rhs.type.isPtr() {
            val tmp = lhs
            lhs = rhs
            rhs = tmp
        }

        # ptr + int
        Assert.that(lhs.type.isPtr())
        Assert.that(rhs.type.isInt())
        rhs = binop(mark, Node.Kind.mul, rhs, intNode(mark, CCIR.ptrSize))
        binop(mark, Node.Kind.add, lhs, rhs)
    }

    def newsub(self, mark: Mark, var lhs: Node, var rhs: Node): Node {
        CCType.addType(lhs)
        CCType.addType(rhs)

        # 'int - int' goes through as is
        if lhs.type.isInt() and rhs.type.isInt() {
            return binop(mark, Node.Kind.sub, lhs, rhs)
        }

        # ptr - int
        if lhs.type.isPtr() and rhs.type.isInt() {
            rhs = binop(mark, Node.Kind.mul, rhs, intNode(mark, CCIR.ptrSize))
            return binop(mark, Node.Kind.sub, lhs, rhs)
        }

        # ptr - ptr
        if lhs.type.isPtr() and rhs.type.isPtr() {
            val diff = binop(mark, Node.Kind.sub, lhs, rhs)
            val node = binop(mark, Node.Kind.div, diff, intNode(mark, CCIR.ptrSize))
            node.type = Type.int
            return node
        }

        errorAtMark("Invalid operands to binary '-' (" + lhs.type + ", " + rhs.type + ")", mark)
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

    def intNode(mark: Mark, value: Int): Node = literal(mark, Node.Kind.int, value)

    def exprStmtNode(expr: Node): Node = unop(expr.mark, Node.Kind.exprStmt, expr)

    def varNode(mark: Mark, var_: Obj): Node {
        val node = Node(mark, Node.Kind.var_)
        node.var_ = var_
        node
    }

    def blockNode(mark: Mark, stmts: List[Node]): Node {
        val node = Node(mark, Node.Kind.block)
        node.body = stmts
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
            case '+' { next(); unop(mark, Node.Kind.pos, exprpr(unaryPrec)) }
            case '-' { next(); unop(mark, Node.Kind.neg, exprpr(unaryPrec)) }
            case '&' { next(); unop(mark, Node.Kind.addr, exprpr(unaryPrec)) }
            case '*' { next(); unop(mark, Node.Kind.deref, exprpr(unaryPrec)) }
            case CCToken.tINT { intNode(mark, next().intValue) }
            case CCToken.tIDENT {
                val name = next().stringValue
                val var_ = locals.get(name, mark)
                varNode(mark, var_)
            }
            else = errorKind("expression")
        }
    }

    ## block = "{" (declaration | stmt)* "}"
    def block(self): Node {
        val mark = mark()
        val body: List[Node] = []
        expect('{')
        while not consume('}') {
            val stmt = if at(CCToken.kwINT) { declaration() } else { stmt() }
            body.add(stmt)
        }
        blockNode(mark, body)
    }

    def declspec(self): Type {
        expect(CCToken.kwINT)
        Type.int
    }

    ## declarator = "*"* ident?
    def declarator(self, var type: Type): Tuple[Mark, String, Type] {
        while consume('*') {
            type = Type.ptr(type)
        }
        val mark = mark()
        val name = if at(CCToken.tIDENT) { next().stringValue } else { "" }
        (mark, name, type)
    }

    ## declaration = declspec (declarator ("=" expr)? ("," declarator ("=" expr)?)*)? ";"
    def declaration(self): Node {
        val mark = mark()
        val baseType = declspec()
        var first = true

        val initstmts: List[Node] = []
        while not consume(';') {
            if not first {
                expect(',')
            }
            first = false
            val (mark, name, type) = declarator(baseType)
            if not name {
                throw CCError("Expected name", [mark])
            }
            val var_ = locals.add(name, type, mark)
            if consume('=') {
                val init = expr()
                initstmts.add(exprStmtNode(
                    binop(mark, Node.Kind.assign, varNode(mark, var_), init)))
            }
        }
        blockNode(mark, initstmts)
    }

    def nop(self, mark: Mark): Node {
        val node = Node(mark, Node.Kind.block)
        node.body = []
        node
    }
}
