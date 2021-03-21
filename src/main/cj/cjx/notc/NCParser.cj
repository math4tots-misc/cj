package cjx.notc

import cjx.notc.NCLocals
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
    static val unaryPrec: Int = precof('*') + 5

    def typeOfToken(token: NCToken): Int = token.type
    def nameOfType(type: Int): String = NCToken.typeRepr(type)

    def parse(program: Program, filepath: String, contents: String) {
        val tokens = NCLexer.lex(filepath, contents)
        val self = Self(filepath, tokens, program)
        file()
        assert(NCToken.tEOF)
    }

    val filepath: String
    val tokens: List[NCToken]
    var i = 0

    # module-level
    val program: Program

    # function-level
    var locals: NCLocals = NCLocals()

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: NCToken): Mark = Mark(filepath, token.line, token.column)
    def errorAt(self, message: String, token: NCToken): NoReturn = errorAtMark(
        message, markAt(token))
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw NCError(
        message, [mark])
    def id(self): String = expect(NCToken.tID).stringValue

    def file(self): Program {
        skipDelims()
        while not at(NCToken.tEOF) {
            val mark = mark()
            if consume(NCToken.kwCONST) {
                val name = id()
                expect('=')
                val value = expect(NCToken.tINT).intValue
                expectDelim()
                program.addConst(name, value)
            } else {
                val type = type()
                val name = id()
                func(mark, type, name)
            }
            skipDelims()
        }
        program
    }

    def param(self): Var {
        val mark = mark()
        val type = type()
        val name = id()
        locals.add(mark, type, name)
    }

    def params(self): List[Var] = parseJoin('(', ')', ',', () -> param())

    def func(self, mark: Mark, returnType: Type, name: String) {
        funcPrep()
        val nparams = params().size()
        val func = Func(mark, returnType, name, nparams, locals.list)
        if consume('=') {
            func.body = expr()
        } else if at('{') {
            func.body = block()
        }
        expectDelim()
        program.addFunc(func)
    }

    def funcPrep(self) {
        locals = NCLocals()
    }

    def type(self): Type {
        var type = switch peek().type {
            case NCToken.kwINT { next(); Type.int }
            case NCToken.kwVOID { next(); Type.void }
            else = errorKind("type")
        }
        while consume('[') {
            expect(']')
            type = Type.array(type)
        }
        type
    }

    def atDelim(self): Bool = switch peek().type {
        case ';'; case '\n'; case NCToken.tEOF; case '}' = true
        else = false
    }

    def expectDelim(self) {
        if not atDelim() {
            errorKind("delimiter")
        }
        skipDelims()
    }

    def skipDelims(self) {
        while consume(';') or consume('\n') {}
    }

    def precof(type: Int): Int = switch type {
        case '('; case '['; case '.' = 140
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
                case '('          { val args = args(); expr = Expr.call(mark, expr, args) }
                case '='          { next(); expr = Expr.assign(mark, expr, exprpr(tokprec - 1)) }
                case '+'          { next(); expr = Expr.add(mark, expr, exprpr(tokprec)) }
                case '-'          { next(); expr = Expr.sub(mark, expr, exprpr(tokprec)) }
                case '*'          { next(); expr = Expr.mul(mark, expr, exprpr(tokprec)) }
                case '/'          { next(); expr = Expr.div(mark, expr, exprpr(tokprec)) }
                case '%'          { next(); expr = Expr.rem(mark, expr, exprpr(tokprec)) }
                case NCToken.tEQ  { next(); expr = Expr.eq(mark, expr, exprpr(tokprec)) }
                case NCToken.tNE  { next(); expr = Expr.ne(mark, expr, exprpr(tokprec)) }
                case NCToken.tLE  { next(); expr = Expr.le(mark, expr, exprpr(tokprec)) }
                case '<'          { next(); expr = Expr.lt(mark, expr, exprpr(tokprec)) }
                case NCToken.tGE  { next(); expr = Expr.le(mark, exprpr(tokprec), expr) }
                case '>'          { next(); expr = Expr.lt(mark, exprpr(tokprec), expr) }
                case '[' {
                    next()
                    if consume(']') {
                        if expr.kind != Expr.kTYPE {
                            throw NCError("Expected type", [expr.mark])
                        }
                        expr = Expr.type(mark, Type.array(expr.ty))
                    } else {
                        val iexpr = expr()
                        expect(']')
                        expr = Expr.getitem(mark, expr, iexpr)
                    }
                }
                else = error("Unhandled operator " + peek().repr())
            }
            tokprec = precof(peek().type)
        }
        expr
    }

    def args(self): List[Expr] = parseJoin('(', ')', ',', () -> expr())

    def atom(self): Expr {
        val mark = mark()
        switch peek().type {
            case '(' { next(); val e = expr(); expect(')'); e }
            case '+' { next(); val e = exprpr(unaryPrec); Expr.pos(mark, e) }
            case '-' { next(); val e = exprpr(unaryPrec); Expr.neg(mark, e) }
            case '{' = block()
            case NCToken.tID {
                val name = next().stringValue
                if val var_ = locals.getOrNull(name) {
                    Expr.getvar(mark, var_)
                } else if val func = program.getFuncOrNull(name) {
                    Expr.getfunc(mark, func)
                } else if val value = program.getConstOrNull(name) {
                    Expr.int(mark, value)
                } else {
                    throw NCError("Variable '" + name + "' not found", [mark])
                }
            }
            case NCToken.tINT = Expr.int(mark, next().intValue)
            case NCToken.kwINT { next(); Expr.type(mark, Type.int) }
            case NCToken.kwVOID { next(); Expr.type(mark, Type.void) }
            case NCToken.tMACROID {
                val name = next().stringValue
                val args = args()
                Expr.macro(mark, name, args)
            }
            else = errorKind("expression")
        }
    }

    def stmt(self): Expr {
        val mark = mark()
        switch peek().type {
            case '{' = block()
            case ';'; case '\n' = { skipDelims(); Expr.nop(mark) }
            case NCToken.kwRETURN {
                next()
                val expr = if atDelim() { Expr.int(mark, 0) } else { expr() }
                expectDelim()
                Expr.ret(mark, expr)
            }
            case NCToken.kwIF {
                next()
                expect('(')
                val cond = expr()
                expect(')')
                skipDelims()
                val then = stmt()
                val els = if consume(NCToken.kwELSE) {
                    skipDelims(); stmt() } else { Expr.nop(mark) }
                Expr.if_(mark, cond, then, els)
            }
            case NCToken.kwWHILE {
                next()
                expect('(')
                val cond = expr()
                expect(')')
                skipDelims()
                val then = stmt()
                Expr.while_(mark, cond, then)
            }
            case NCToken.kwFOR {
                next()
                expect('(')
                val init = if consume(';') { Expr.nop(mark) } else { stmt() }
                val cond = if at(';') { Expr.int(mark, 1) } else { expr() }
                expect(';')
                val incr = if at(')') { Expr.int(mark, 0) } else { expr() }
                expect(')')
                skipDelims()
                val then = stmt()
                Expr.block(mark, [
                    init,
                    Expr.while_(mark, cond, Expr.block(mark, [
                        then,
                        incr,
                    ])),
                ])
            }
            else {
                val expr = expr()
                if expr.kind == Expr.kTYPE {
                    declaration(mark, expr.ty)
                } else {
                    expectDelim()
                    expr
                }
            }
        }
    }

    def declaration(self, mark: Mark, type: Type): Expr {
        var repeat = true
        val exprs: List[Expr] = []
        while repeat {
            val name = id()
            val var_ = locals.add(mark, type, name)
            if consume('=') {
                exprs.add(Expr.setvar(mark, var_, expr()))
            }
            repeat = consume(',')
        }
        expectDelim()
        Expr.block(mark, exprs)
    }

    def block(self): Expr {
        val mark = mark()
        expect('{')
        val exprs: List[Expr] = []
        while not consume('}') {
            exprs.add(stmt())
        }
        Expr.block(mark, exprs)
    }
}
