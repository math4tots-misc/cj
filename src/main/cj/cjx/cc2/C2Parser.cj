package cjx.cc2

import cjx.cc2.C2ExprBuilder
import cjx.parser.Mark
import cjx.cc2.C2Locals
import cjx.parser.MError
import cjx.parser.ParserMixin
import cjx.cc2.C2Token
import cjx.cc2.C2IR.Func
import cjx.cc2.C2IR.TranslationUnit
import cjx.cc2.C2IR.Stmt
import cjx.cc2.C2IR.Expr
import cjx.cc2.C2IR.Type
import cjx.cc2.C2IR.Var

class C2Parser : ParserMixin[C2Token] {
    static private val assingPrec: Int = precof('=')
    static private val unaryPrec: Int = precof('*') + 5

    def typeOfToken(token: C2Token): Int = token.type
    def nameOfType(type: Int): String = C2Token.typeRepr(type)

    def parse(tokens: List[C2Token]): TranslationUnit {
        val self = Self(tokens)
        translationUnit()
        translationUnit
    }

    val tokens: List[C2Token]
    var i = 0
    val translationUnit: TranslationUnit = TranslationUnit()
    var _locals: C2Locals? = null
    val eb: C2ExprBuilder = C2ExprBuilder()

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: C2Token): Mark = Mark(token.filepath, token.line, token.column)
    def errorAt(self, message: String, token: C2Token): NoReturn = throw MError(
        message, [markAt(token)])
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw MError(
        message, [mark])

    def __get_locals(self): C2Locals = _locals.get()

    def precof(type: Int): Int = switch type {
        case '*'; case '/'; case '%' = 120
        case '+'; case '-' = 100
        case '<'; case '>'; case C2Token.tLE; case C2Token.tGE = 80
        case C2Token.tEQ; case C2Token.tNE = 70
        case '=' = 50
        else = -1
    }

    def translationUnit(self) {
        while not at(C2Token.tEOF) {
            func()
        }
    }

    def func(self) {
        _locals = null(C2Locals())

        var baseType = declspec()
        val (mark, name, funcType) = declarator(baseType)
        val func = Func(mark, name, funcType)
        for param in funcType.params {
            locals.add(param.mark, param.type, param.name)
        }
        func.body = block()
        func.locals = locals.list
        translationUnit.addFunc(func)

        _locals = null
    }

    # ========================================================================
    # types
    # ========================================================================

    def atDeclaration(self): Bool {
        switch peek().type {
            case C2Token.kwVOID
            case C2Token.kwINT = true
            else = false
        }
    }

    ## declaration = declspec (declarator ("=" expr)? ("," declarator ("=" expr)?)*)? ";"
    def declaration(self): Stmt {
        val mark = mark()
        val baseType = declspec()
        var first = true

        val initstmts: List[Stmt] = []
        while not consume(';') {
            if not first {
                expect(',')
            }
            first = false
            val (mark, name, type) = declarator(baseType)
            if not name {
                throw MError("Expected name", [mark])
            }
            val var_ = locals.add(mark, type, name)
            if consume('=') {
                val init = expr()
                initstmts.add(eb.exprStmt(
                    mark, eb.binop(mark, '=', eb.getvar(mark, var_), init)))
            }
        }
        eb.block(mark, initstmts)
    }

    def declspec(self): Type {
        val mark = mark()
        switch peek().type {
            case C2Token.kwVOID { next(); Type.void }
            case C2Token.kwINT { next(); Type.int }
            else = throw MError("Expected declaration", [mark])
        }
    }

    def declarator(self, var type: Type): Tuple[Mark, String, Type] {
        while consume('*') {
            type = Type.ptr(Type.Ptr(type))
        }
        val mark = mark()
        val name = if at(C2Token.tIDENT) { next().stringValue } else { "" }

        # type suffix
        type = typeSuffix(type)
        (mark, name, type)
    }

    def typeSuffix(self, var type: Type): Type {
        var repeat = true
        while repeat {
            if consume('(') {
                val params: List[Var] = []
                while not consume(')') {
                    val baseType = declspec()
                    val (mark, paramName, paramType) = declarator(baseType)
                    params.add(Var(mark, paramName, paramType, -1))
                    if not consume(',') { assert(')') }
                }
                type = Type.func(Type.Func(type, params))
            } else {
                repeat = false
            }
        }
        type
    }

    # ========================================================================
    # statements
    # ========================================================================

    def stmt(self): Stmt {
        val mark = mark()
        switch peek().type {
            case C2Token.kwRETURN {
                next()
                val ret = eb.ret(mark, expr())
                expect(';')
                ret
            }
            else = {
                val ret = eb.exprStmt(mark, expr())
                expect(';')
                ret
            }
        }
    }

    def block(self): Stmt {
        val mark = mark()
        val stmts: List[Stmt] = []
        expect('{')
        while not consume('}') {
            val stmt = if atDeclaration() { declaration() } else { stmt() }
            stmts.add(stmt)
        }
        eb.block(mark, stmts)
    }

    # ========================================================================
    # expressions
    # ========================================================================

    def expr(self): Expr = exprpr(0)

    def exprpr(self, precedence: Int): Expr {
        var expr = atom()
        var tokprec = precof(peek().type)
        while precedence < tokprec {
            val mark = mark()
            switch peek().type {
                case '+';case '-';case '*';case '/';case '%'
                case C2Token.tEQ;case C2Token.tNE
                case '<'; case C2Token.tLE
                case '>'; case C2Token.tGE {
                    # left associative binops
                    val type = next().type
                    expr = eb.binop(mark, type, expr, exprpr(tokprec))
                }
                case '=' {
                    # right associative binops
                    val type = next().type
                    expr = eb.binop(mark, type, expr, exprpr(tokprec - 1))
                }
                else = error("Unhandled operator " + peek().repr())
            }
            tokprec = precof(peek().type)
        }
        expr
    }

    def atom(self): Expr {
        val mark = mark()
        switch peek().type {
            case C2Token.tINT = eb.int(mark, next().intValue)
            case '-'; case '+' {
                val type = next().type
                eb.preop(mark, type, exprpr(unaryPrec))
            }
            case '(' {
                next()
                val inner = expr()
                expect(')')
                inner
            }
            else = errorKind("expression")
        }
    }
}
