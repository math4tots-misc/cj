package cjx.n2

import cjx.n2.N2Locals
import cjx.n2.N2Lexer
import cjx.n2.N2IR.Expr
import cjx.n2.N2IR.Type
import cjx.n2.N2IR.Func
import cjx.n2.N2IR.Program
import cjx.n2.N2IR.Var
import cjx.n2.N2Error
import cjx.parser.Mark
import cjx.n2.N2Token
import cjx.parser.ParserMixin

class N2Parser: ParserMixin[N2Token] {
    static val unaryPrec: Int = precof('*') + 5

    def typeOfToken(token: N2Token): Int = token.type
    def nameOfType(type: Int): String = N2Token.typeRepr(type)

    def parseAll(sources: List[List[N2Token]]): Program {
        val program = Program()
        for pass in [0, 1, 2] {
            for tokens in sources {
                parseEx(pass, program, tokens)
            }
        }
        program
    }

    def parseEx(pass: Int, program: Program, tokens: List[N2Token]) {
        val self = Self(pass, tokens, program)
        file()
        assert(N2Token.tEOF)
    }

    val pass: Int
    val tokens: List[N2Token]
    var i = 0

    # module-level
    val program: Program

    # function-level
    var locals: N2Locals = N2Locals()

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: N2Token): Mark = token.toMark()
    def errorAt(self, message: String, token: N2Token): NoReturn = errorAtMark(
        message, markAt(token))
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw N2Error(
        message, [mark])
    def id(self): String = expect(N2Token.tID).stringValue

    def file(self): Program {
        skipDelims()
        while not at(N2Token.tEOF) {
            val mark = mark()
            if consume(N2Token.kwCONST) {
                val name = id()
                expect('=')
                val value = expect(N2Token.tINT).intValue
                expectDelim()
                if pass == 0 { program.addConst(name, value) }
            } else if pass < 1 {
                skipToDelimiter()
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
        locals = N2Locals()
        val nparams = params().size()
        val func = Func(mark, returnType, name, nparams, locals.list)
        if pass < 2 {
            program.addFunc(func)
            skipToDelimiter()
        } else {
            if at('=') or at('{') {
                val body = if consume('=') { expr() } else { block() }
                func.body = body.icast(returnType)
                program.updateFunc(func)
            }
        }
        expectDelim()
    }

    def skipToDelimiter(self) {
        while not atDelim() {
            skipOne()
        }
    }

    def skipOne(self) {
        var repeat = true
        var depth = 0
        while repeat {
            switch next().type {
                case '('; case '['; case '{' { depth++ }
                case ')'; case ']'; case '}' { depth-- }
                else = ()
            }
            repeat = depth > 0
        }
    }

    def type(self): Type {
        var type = switch peek().type {
            case N2Token.kwINT { next(); Type.int }
            case N2Token.kwVOID { next(); Type.void }
            case N2Token.kwSTR { next(); Type.str }
            case N2Token.kwVAR { next(); Type.var_ }
            else = errorKind("type")
        }
        while consume('[') {
            expect(']')
            type = Type.array(type)
        }
        type
    }

    def atDelim(self): Bool = switch peek().type {
        case ';'; case '\n'; case N2Token.tEOF; case '}' = true
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
        case '<'; case '>'; case N2Token.tLE; case N2Token.tGE = 80
        case N2Token.tEQ; case N2Token.tNE = 70
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
                case N2Token.tEQ  { next(); expr = Expr.eq(mark, expr, exprpr(tokprec)) }
                case N2Token.tNE  { next(); expr = Expr.ne(mark, expr, exprpr(tokprec)) }
                case N2Token.tLE  { next(); expr = Expr.le(mark, expr, exprpr(tokprec)) }
                case '<'          { next(); expr = Expr.lt(mark, expr, exprpr(tokprec)) }
                case N2Token.tGE  { next(); expr = Expr.le(mark, exprpr(tokprec), expr) }
                case '>'          { next(); expr = Expr.lt(mark, exprpr(tokprec), expr) }
                case '[' {
                    next()
                    if consume(']') {
                        if expr.kind != Expr.kTYPE {
                            throw N2Error("Expected type", [expr.mark])
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
            case N2Token.tID {
                val name = next().stringValue
                if val var_ = locals.getOrNull(name) {
                    Expr.getvar(mark, var_)
                } else if val func = program.getFuncOrNull(name) {
                    Expr.getfunc(mark, func)
                } else if val value = program.getConstOrNull(name) {
                    Expr.int(mark, value)
                } else {
                    throw N2Error("Variable '" + name + "' not found", [mark])
                }
            }
            case N2Token.tINT = Expr.int(mark, next().intValue)
            case N2Token.tSTRING = Expr.str(mark, next().stringValue)
            case N2Token.kwINT { next(); Expr.type(mark, Type.int) }
            case N2Token.kwVOID { next(); Expr.type(mark, Type.void) }
            case N2Token.kwSTR { next(); Expr.type(mark, Type.str) }
            case N2Token.kwVAR { next(); Expr.type(mark, Type.var_) }
            case N2Token.tMACROID {
                val name = next().stringValue
                val args = args()
                Expr.macro(mark, name, args)
            }
            else = errorKind("expression")
        }
    }

    def stmt(self): Expr {
        val stmt = _stmt()
        skipDelims()
        stmt
    }

    def _stmt(self): Expr {
        val mark = mark()
        switch peek().type {
            case '{' = block()
            case ';' = { skipDelims(); Expr.nop(mark) }
            case N2Token.kwRETURN {
                next()
                val expr = if atDelim() { Expr.int(mark, 0) } else { expr() }
                expectDelim()
                Expr.ret(mark, expr)
            }
            case N2Token.kwIF {
                next()
                expect('(')
                val cond = expr()
                expect(')')
                skipDelims()
                val then = stmt()
                val els = if consume(N2Token.kwELSE) {
                    skipDelims(); stmt() } else { Expr.nop(mark) }
                Expr.if_(mark, cond, then, els)
            }
            case N2Token.kwWHILE {
                next()
                expect('(')
                val cond = expr()
                expect(')')
                skipDelims()
                val then = stmt()
                Expr.while_(mark, cond, then)
            }
            case N2Token.kwFOR {
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
            exprs.add(Expr.declvar(mark, var_,
                if consume('=') { null(expr()) } else { null }))
            repeat = consume(',')
        }
        expectDelim()
        Expr.seq(mark, exprs)
    }

    def block(self): Expr {
        val mark = mark()
        expect('{')
        val exprs: List[Expr] = []
        skipDelims()
        while not consume('}') {
            exprs.add(stmt())
            skipDelims()
        }
        Expr.block(mark, exprs)
    }
}
