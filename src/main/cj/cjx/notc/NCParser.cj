package cjx.notc

import cjx.notc.NCLexer
import cjx.notc.NCIR.Expr
import cjx.notc.NCIR.Type
import cjx.notc.NCIR.Func
import cjx.notc.NCIR.Program
import cjx.notc.NCIR.Var
import cjx.notc.NCError
import cjx.parser.Mark
import cjx.notc.NCToken
import cjx.parser.ParserMixin

class NCParser: ParserMixin[NCToken] {
    def typeOfToken(token: NCToken): Int = token.type
    def nameOfType(type: Int): String = NCToken.typeRepr(type)

    def parse(filepath: String, contents: String): Program {
        val tokens = NCLexer.lex(filepath, contents)
        val self = Self(filepath, tokens)
        program()
        assert(NCToken.tEOF)
        program
    }

    val filepath: String
    val tokens: List[NCToken]
    var i = 0

    # module-level
    val program: Program = Program()

    # function-level
    var locals: List[Var] = []

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: NCToken): Mark = Mark(filepath, token.line, token.column)
    def errorAt(self, message: String, token: NCToken): NoReturn = errorAtMark(
        message, markAt(token))
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw NCError(
        message, [mark])
    def id(self): String = expect(NCToken.tID).stringValue

    def program(self): Program {
        val program = Program()
        while not at(NCToken.tEOF) {
            val mark = mark()
            val type = type()
            val name = id()
            func(mark, type, name)
        }
        program
    }

    def param(self): Var {
        val mark = mark()
        val type = type()
        val name = id()
        val index = locals.size()
        val var_ = Var(mark, type, name, index)
        locals.add(var_)
        var_
    }

    def params(self): List[Var] = parseJoin('(', ')', ',', () -> param())

    def func(self, mark: Mark, returnType: Type, name: String) {
        funcPrep()
        val nparams = params().size()
        val func = Func(mark, returnType, name, nparams, locals)
        if consume('=') { func.body = expr() } else { expect(';') }
        program.funcs.add(func)
    }

    def funcPrep(self) {
        locals = []
    }

    def type(self): Type {
        switch peek().type {
            case NCToken.kwINT { next(); Type.int }
            else = errorKind("type")
        }
    }

    def atType(self): Bool {
        switch peek().type {
            case NCToken.kwINT = true
            else = false
        }
    }

    def precof(type: Int): Int = switch type {
        case '*'; case '/'; case '%' = 120
        case '+'; case '-' = 100
        case '<'; case '>'; case NCToken.tLE; case NCToken.tGE = 80
        case NCToken.tEQ; case NCToken.tNE = 70
        case '=' = 50
        else = -1
    }

    def expr(self): Expr = exprpr(0)

    def exprpr(self, precedence: Int): Expr {
        var expr = atom()
        var tokprec = precof(peek().type)
        while precedence < tokprec {
            val mark = mark()
            switch peek().type {
                case '+' { next(); expr = Expr.add(mark, expr, exprpr(tokprec)) }
                case '-' { next(); expr = Expr.sub(mark, expr, exprpr(tokprec)) }
                else = error("Unhandled operator " + peek().repr())
            }
            tokprec = precof(peek().type)
        }
        expr
    }

    def atom(self): Expr {
        val mark = mark()
        switch peek().type {
            case '(' { val e = expr(); expect(')'); e }
            case NCToken.tINT = Expr.int(mark, next().intValue)
            else = errorKind("expression")
        }
    }
}
