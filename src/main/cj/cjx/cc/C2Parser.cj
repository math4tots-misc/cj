package cjx.cc

import cjx.cc.C2Scope
import cj.Math
import cjx.cc.C2ExprBuilder
import cjx.parser.Mark
import cjx.cc.C2Locals
import cjx.parser.MError
import cjx.parser.ParserMixin
import cjx.cc.C2Token
import cjx.cc.C2IR.Func
import cjx.cc.C2IR.TranslationUnit
import cjx.cc.C2IR.Stmt
import cjx.cc.C2IR.Expr
import cjx.cc.C2IR.Type
import cjx.cc.C2IR.Var
import cjx.cc.C2IR.GVar

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
    val scope: C2Scope = C2Scope()
    val eb: C2ExprBuilder = C2ExprBuilder()
    var currentFunc: Func? = null

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: C2Token): Mark = Mark(token.filepath, token.line, token.column)
    def errorAt(self, message: String, token: C2Token): NoReturn = throw MError(
        message, [markAt(token)])
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw MError(
        message, [mark])

    def __get_locals(self): C2Locals = scope._locals.get()
    def __get_translationUnit(self): TranslationUnit = scope.translationUnit

    def precof(type: Int): Int = switch type {
        case '.'; case C2Token.tARROW; case '('; case '[';
        case C2Token.tINCR; case C2Token.tDECR = 150
        case '*'; case '/'; case '%' = 120
        case '+'; case '-' = 100
        case '<'; case '>'; case C2Token.tLE; case C2Token.tGE = 80
        case C2Token.tEQ; case C2Token.tNE = 70
        case '=' = 50
        case ',' = 10
        else = -1
    }

    def translationUnit(self) {
        while not at(C2Token.tEOF) {
            val baseType = declspec()
            if atFunc(baseType) {
                func(baseType)
            } else {
                gvar(baseType)
            }
        }
    }

    def gvar(self, baseType: Type) {
        var first = true
        while not consume(';') {
            if not first { expect(',') }
            first = false
            val (mark, name, type) = declarator(baseType)
            translationUnit.addGVar(GVar(mark, name, type))
        }
    }

    def atFunc(self, baseType: Type): Bool {
        val savedI = i
        val ret = declarator(baseType).f2.isFunc()
        i = savedI
        ret
    }

    def func(self, baseType: Type) {
        val (mark, name, funcType) = declarator(baseType)
        val func = if val f = translationUnit.getFuncOrNull(name) {
            scope._locals = null(f.locals)
            f
        } else {
            scope._locals = null(C2Locals())
            val f = when funcType {
                case func(ft) = Func(mark, name, ft)
                else = throw MError("Expected function type", [mark])
            }
            for param in funcType.params {
                locals.add(param.mark, param.type, param.name)
            }
            f.locals = locals
            translationUnit.addFunc(f)
            f
        }

        if not consume(';') {
            if is_set!(func, body) {
                throw MError("Duplicate function definition " + func.name, [mark, func.mark])
            }
            currentFunc = null(func)
            func.body = block()
            currentFunc = null
        }

        scope._locals = null
    }

    # ========================================================================
    # types
    # ========================================================================

    def atTypename(self): Bool {
        switch peek().type {
            case C2Token.kwVOID
            case C2Token.kwCHAR
            case C2Token.kwINT
            case C2Token.kwSHORT
            case C2Token.kwLONG
            case C2Token.kwUNION
            case C2Token.kwSTRUCT = true
            else = false
        }
    }

    ## declaration = declspec (declarator ("=" expr)? ("," declarator ("=" expr)?)*)? ";"
    def declaration(self): List[Stmt] {
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
            initstmts.add(eb.declvar(var_))
            if consume('=') {
                val init = assign()
                initstmts.add(eb.exprStmt(
                    mark, eb.binop(mark, '=', eb.getvar(mark, var_), init)))
            }
        }
        initstmts
    }

    def declspec(self): Type {
        val mark = mark()
        switch peek().type {
            case C2Token.kwSTRUCT; case C2Token.kwUNION { return declspecStructOrUnion() }
            else = ()
        }

        # NOTE: some invalid combinations of types may be allowed,
        # but at least the valid ones should be handled properly.
        #
        # we skip by two digits at a time to recognize when a pattern has
        # appeared twice (of course, a pattern that appears too many times
        # may potentially result in weird behavior)
        var flags = 0
        val fvoid = 1 << 0
        var fchar = 1 << 2
        var fshort = 1 << 4
        var fint = 1 << 6
        var flong = 1 << 8
        var type: Type = Type.int
        while atTypename() {
            switch peek().type {
                case C2Token.kwVOID { next(); flags += fvoid }
                case C2Token.kwINT { next(); flags += fint }
                case C2Token.kwLONG { next(); flags += flong }
                case C2Token.kwCHAR { next(); flags += fchar }
                case C2Token.kwSHORT { next(); flags += fshort }
                case C2Token.kwSTRUCT; case C2Token.kwUNION {
                    errorKind("struct/union cannot mix with primitive types")
                }
                else = errorKind("typename")
            }
        }
        switch flags {
            case fvoid = Type.void
            case fint = Type.int
            case flong; case flong + fint; case flong + flong = Type.long
            case fchar = Type.char
            case fshort; case fshort + fint = Type.short
            case 0 = errorKind("typename")
            else = throw MError("Invalid type", [mark])
        }
    }

    def declspecStructOrUnion(self): Type {
        val mark = mark()
        val isUnion = if consume(C2Token.kwUNION) { true } else {
            expect(C2Token.kwSTRUCT); false }
        val optTag = if at(C2Token.tIDENT) { null(next().stringValue) } else { null }
        if val tag = optTag {
            val optTaggable = if at('{') {
                # If a body is present, you don't want to check parent scopes
                scope.getCurrentScopeTaggableOrNull(tag)
            } else {
                scope.getTaggableOrNull(tag)
            }
            val structOrUnion = if val taggable = optTaggable {
                when taggable {
                    case structOrUnion(s) {
                        if s.isUnion() == isUnion { s } else {
                            throw MError(
                                "Conflicting taggable kind", [mark, taggable.mark])
                        }
                    }
                    else = throw MError(
                        "Conflicting taggable kind", [mark, taggable.mark])
                }
            } else {
                val s = Type.StructOrUnion(mark, isUnion, optTag)
                scope.addTaggable(s)
                s
            }
            if at('{') { structOrUnionDecl(structOrUnion, isUnion) }
            structOrUnion
        } else {
            # When no tag is provided, assume a struct or union body always follows
            val structOrUnion = Type.StructOrUnion(mark, isUnion, optTag)
            structOrUnionDecl(structOrUnion, isUnion)
            structOrUnion
        }
    }

    def structOrUnionDecl(self, structOrUnion: Type.StructOrUnion, isUnion: Bool) {
        if structOrUnion.isComplete() {
            throw MError("Duplicate struct or union definition", [mark(), structOrUnion.mark])
        }
        expect('{')
        var currentSize = 0
        var currentAlignment = 1
        while not consume('}') {
            val baseType = declspec()
            var first = true
            while not consume(';') {
                if not first { expect(',') }
                first = false
                val (memberMark, memberName, memberType) = declarator(baseType)
                currentAlignment = Math.max(currentAlignment, memberType.alignment())

                if isUnion {
                    val member = Type.StructOrUnion.Member(memberMark, memberName, memberType, 0)
                    currentSize = Math.max(currentSize, member.type.size())
                    structOrUnion.members.add(member)
                } else {
                    currentSize = currentSize.roundUp(memberType.alignment())
                    val member = Type.StructOrUnion.Member(memberMark, memberName, memberType, currentSize)
                    currentSize += member.type.size()
                    structOrUnion.members.add(member)
                }
            }
        }
        structOrUnion._alignment = currentAlignment
        structOrUnion._size = currentSize.roundUp(currentAlignment)
    }

    def declarator(self, var type: Type): Tuple[Mark, String, Type] {
        while consume('*') {
            type = type.ptrOf()
        }

        if consume('(') {
            val savedStartI = i
            declarator(type) # skip the part inside the parens for now
            expect(')')

            # parse the suffix first
            type = typeSuffix(type)
            val savedEndI = i

            # go back and parse the part we skipped
            i = savedStartI
            val result = declarator(type)

            # go back to the point after the suffix
            i = savedEndI

            result
        } else {
            val mark = mark()
            val name = if at(C2Token.tIDENT) { next().stringValue } else { "" }
            type = typeSuffix(type)
            (mark, name, type)
        }
    }

    def typeSuffix(self, var type: Type): Type {
        if consume('(') {
            val params: List[Var] = []
            while not consume(')') {
                val baseType = declspec()
                val (mark, paramName, paramType) = declarator(baseType)
                params.add(Var(mark, paramName, paramType, -1))
                if not consume(',') { assert(')') }
            }
            Type.func(Type.Func(typeSuffix(type), params))
        } else if consume('[') {
            val len = expect(C2Token.tINT).intValue
            expect(']')
            typeSuffix(type).arrayOf(len)
        } else {
            type
        }
    }

    # ========================================================================
    # statements
    # ========================================================================

    def stmt(self): Stmt {
        val mark = mark()
        switch peek().type {
            case '{' = block()
            case ';' { while consume(';') {}; eb.nop(mark) }
            case C2Token.kwRETURN {
                next()
                val ret = if val func = currentFunc {
                    val rtype = func.type.returnType
                    val rexpr = eb.icast(expr(), rtype)
                    eb.ret(mark, rexpr)
                } else {
                    throw MError("Return can only be used inside a function body", [mark])
                }
                expect(';')
                ret
            }
            case C2Token.kwFOR {
                next()
                expect('(')
                val inits = if not consume(';') { declOrStmt() } else { [] }
                val cond = if at(';') { eb.int(mark, 1) } else { expr() }
                expect(';')
                val incr = if at(')') { eb.int(mark, 0) } else { expr() }
                expect(')')
                val then = stmt()
                eb.for_(mark, inits, cond, incr, then)
            }
            case C2Token.kwWHILE {
                next()
                expect('(')
                val cond = expr()
                expect(')')
                val then = stmt()
                eb.while_(mark, cond, then)
            }
            case C2Token.kwIF {
                next()
                expect('(')
                val cond = expr()
                expect(')')
                val then = stmt()
                val els = if consume(C2Token.kwELSE) { stmt() } else { eb.nop(mark) }
                eb.if_(mark, cond, then, els)
            }
            else {
                val expr = expr()
                val ret = eb.exprStmt(mark, expr)
                expect(';')
                ret
            }
        }
    }

    def declOrStmt(self): List[Stmt] {
        if atTypename() { declaration() } else { [stmt()] }
    }

    def blockInside(self): List[Stmt] {
        val stmts: List[Stmt] = []
        expect('{')
        locals.scoped(() -> {
            while not consume('}') {
                stmts.addAll(declOrStmt())
            }
        })
        stmts
    }

    def block(self): Stmt {
        val mark = mark()
        eb.block(mark, blockInside())
    }

    # ========================================================================
    # expressions
    # ========================================================================

    def expr(self): Expr = exprpr(0)
    def assign(self): Expr = exprpr(assingPrec)
    def unary(self): Expr = exprpr(unaryPrec)

    def exprpr(self, precedence: Int): Expr {
        var expr = atom()
        var tokprec = precof(peek().type)
        while precedence < tokprec {
            val mark = mark()
            switch peek().type {
                case '+';case '-';case '*';case '/';case '%';case ','
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
                case '[' {
                    # a[b] is alias for *(a+b)
                    next()
                    val indexExpr = expr()
                    expect(']')
                    expr = eb.preop(mark, '*', eb.binop(mark, '+', expr, indexExpr))
                }
                case C2Token.tINCR; case C2Token.tDECR {
                    # postfix operators
                    val type = next().type
                    expr = eb.postop(mark, type, expr)
                }
                case '(' { expr = eb.call(mark, expr, args()) }
                case '.' {
                    next()
                    val memberName = expect(C2Token.tIDENT).stringValue
                    expr = eb.getmember(mark, expr, memberName)
                }
                case C2Token.tARROW {
                    next()
                    val memberName = expect(C2Token.tIDENT).stringValue
                    expr = eb.getmember(mark, eb.preop(mark, '*', expr), memberName)
                }
                else = error("Unhandled operator " + peek().repr())
            }
            tokprec = precof(peek().type)
        }
        expr
    }

    def args(self): List[Expr] {
        val args: List[Expr] = []
        expect('(')
        while not consume(')') {
            args.add(assign())
            if not consume(',') { assert(')') }
        }
        args
    }

    def atom(self): Expr {
        val mark = mark()
        switch peek().type {
            case C2Token.tINT = eb.int(mark, next().intValue)
            case C2Token.tLONG = eb.long(mark, next().bigIntValue)
            case C2Token.tCHAR = eb.char(mark, next().intValue)
            case C2Token.tSTR = eb.str(mark, next().bytesValue)
            case '-'; case '+'; case '&'; case '*'
            case C2Token.tINCR; case C2Token.tDECR {
                val type = next().type
                eb.preop(mark, type, unary())
            }
            case '(' {
                next()
                if at('{') {
                    val stmts = blockInside()
                    expect(')')
                    eb.stmtExpr(mark, stmts)
                } else {
                    val inner = expr()
                    expect(')')
                    inner
                }
            }
            case C2Token.tIDENT {
                val name = next().stringValue
                if val var_ = locals.getOrNull(name) {
                    eb.getvar(mark, var_)
                } else if val func = translationUnit.getFuncOrNull(name) {
                    eb.func(mark, func)
                } else if val gvar = translationUnit.getGVarOrNull(name) {
                    eb.getgvar(mark, gvar)
                } else {
                    throw MError("Variable '" + name + "' not found", [mark])
                }
            }
            case C2Token.kwSIZEOF {
                next()
                val expr = unary()
                if not expr.type.isComplete() {
                    throw MError("" + expr.type + " is an incomplete type", [mark])
                }
                eb.int(mark, expr.type.size())
            }
            else = errorKind("expression")
        }
    }
}
