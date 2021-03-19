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
        val p = program()
        assert(NCToken.tEOF)
        p
    }

    def parseExpression(filepath: String, contents: String): Expr = {
        val tokens = NCLexer.lex(filepath, contents)
        val self = Self(filepath, tokens)
        val expr = expr()
        assert(NCToken.tEOF)
        expr
    }

    val filepath: String
    val tokens: List[NCToken]
    var i = 0
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
            program.funcs.add(func(mark, type, name))
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

    def func(self, mark: Mark, returnType: Type, name: String): Func {
        funcPrep()
        val nparams = params().size()
        val func = Func(mark, returnType, name, nparams, locals)
        if consume('=') { func.body = expr() } else { expect(';') }
        func
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

    def expr(self): Expr = atom()

    def atom(self): Expr {
        val mark = mark()
        switch peek().type {
            case '(' { val e = expr(); expect(')'); e }
            case NCToken.tINT = Expr.int(mark, next().intValue)
            else = errorKind("expression")
        }
    }
}
