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
import cjx.cc.C2IR.Ordinary
import cjx.cc.C2IR.VarAttr
import cjx.cc.C2IR.Typedef
import cjx.cc.C2IR.EnumConstant

class C2Parser : ParserMixin[C2Token] {
    static private val assingPrec: Int = precof('=')
    static private val unaryPrec: Int = precof('*') + 5
    static private val condPrec: Int = precof('?')

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
    var funcTmpVarCount = 0

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
        case '*'; case '/'; case '%' = 130
        case '+'; case '-' = 120
        case C2Token.tSHL; case C2Token.tSHR = 110
        case '<'; case '>'; case C2Token.tLE; case C2Token.tGE = 100
        case C2Token.tEQ; case C2Token.tNE = 90
        case '&' = 80
        case '^' = 70
        case '|' = 60
        case C2Token.tAND = 50
        case C2Token.tOR = 40
        case '?' = 30
        case '='; case C2Token.tPLUS_EQ; case C2Token.tMINUS_EQ
        case C2Token.tSTAR_EQ; case C2Token.tDIV_EQ; case C2Token.tREM_EQ
        case C2Token.tAND_EQ; case C2Token.tOR_EQ; case C2Token.tXOR_EQ
        case C2Token.tSHL_EQ; case C2Token.tSHR_EQ = 20
        case ',' = 10
        else = -1
    }

    def translationUnit(self) {
        while not at(C2Token.tEOF) {
            val (baseType, attr) = declspecEx()
            if attr.typedef {
                typedef(baseType)
            } else if atFunc(baseType) {
                func(baseType, attr)
            } else {
                gvar(baseType)
            }
        }
    }

    def typedef(self, baseType: Type) {
        var first = true
        while not consume(';') {
            if not first { expect(',') }
            first = false
            val (mark, name, type) = declarator(baseType)
            scope.addTypedef(Typedef(mark, name, type))
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

    private def translateTypeForParameterContext(self, paramtype: Type): Type {
        # "array of T" is converted to "pointer to T" only in the parameter context
        if paramtype.isArray() { paramtype.base.ptrOf() } else { paramtype }
    }

    def func(self, baseType: Type, attr: VarAttr) {
        val (mark, name, declaredFuncType) = declarator(baseType)
        val funcType: Type = Type.Func(
            declaredFuncType.returnType,
            declaredFuncType.params.map(p -> Var(
                p.mark,
                p.name,
                translateTypeForParameterContext(p.type),
                p.index)))
        val func = if val ordinary = translationUnit.getOrNull(name) {
            when ordinary {
                case func(f) {
                    f.attr.add(attr)
                    scope._locals = null(f.locals)
                    f
                }
                else = throw MError("Conflicting definition for " + name, [mark, ordinary.mark])
            }
        } else {
            scope._locals = null(C2Locals())
            val f = when funcType {
                case func(ft) = Func(mark, attr, name, ft)
                else = throw MError("Expected function type", [mark])
            }
            for param in funcType.params {
                locals.addLVar(param.mark, param.type, param.name)
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
            funcTmpVarCount = 0
            func.body = block()
            currentFunc = null
        }

        scope._locals = null
    }

    def newTmpvarname(self): String {
        val name = "__T" + funcTmpVarCount
        funcTmpVarCount++
        name
    }

    # ========================================================================
    # types
    # ========================================================================

    private def atTypename(self): Bool {
        switch peek().type {
            case C2Token.kwVOID
            case C2Token.kwBOOL
            case C2Token.kwCHAR
            case C2Token.kwINT
            case C2Token.kwSHORT
            case C2Token.kwLONG
            case C2Token.kwUNION
            case C2Token.kwSTRUCT
            case C2Token.kwENUM
            case C2Token.kwSTATIC
            case C2Token.kwTYPEDEF = true
            case C2Token.tIDENT = if val ordinary = scope.getOrNull(peek().stringValue) {
                tag!(ordinary) == tag!(Ordinary, typedef) } else { false }
            else = false
        }
    }

    ## declaration = declspec (declarator ("=" expr)? ("," declarator ("=" expr)?)*)? ";"
    private def declaration(self): List[Stmt] {
        val mark = mark()
        val (baseType, attrs) = declspecEx()

        if attrs.typedef {
            typedef(baseType)
            return []
        }

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
            val var_ = locals.addLVar(mark, type, name)
            if consume('=') {
                val initExpr = lvarInitializer(var_)
                initstmts.add(eb.exprStmt(mark, initExpr))
            }
        }
        initstmts
    }

    private def declspec(self): Type {
        val mark = mark()
        val (type, attr) = declspecEx()
        if attr {
            throw MError("storage class specifier is not allowed in this context", [mark])
        }
        type
    }

    private def declspecEx(self): Tuple[Type, VarAttr] {
        # NOTE: some invalid combinations of types may be allowed,
        # but at least the valid ones should be handled properly.
        #
        # We skip flags by two bits at a time to recognize when a pattern has
        # appeared twice (of course, a pattern that appears too many times
        # may potentially result in weird behavior)
        val mark = mark()
        val attr = VarAttr()
        var flags = 0
        val fvoid = 1 << 0
        val fbool = 1 << 2
        var fchar = 1 << 4
        var fshort = 1 << 6
        var fint = 1 << 8
        var flong = 1 << 10
        var fother = 1 << 12
        var type: Type = Type.int
        while atTypename() {
            switch peek().type {
                case C2Token.kwTYPEDEF { next(); attr.typedef = true }
                case C2Token.kwSTATIC { next(); attr.static_ = true }
                case C2Token.kwSTRUCT; case C2Token.kwUNION {
                    flags += fother
                    type = declspecDerived()
                }
                case C2Token.kwENUM {
                    flags += fother
                    declspecEnum()
                    type = Type.int
                }
                case C2Token.tIDENT {
                    val name = next().stringValue
                    flags += fother
                    type = if val ordinary = scope.getOrNull(name) {
                        when ordinary {
                            case typedef(t) = t.type
                            else = throw MError(name + " is not a typename", [mark])
                        }
                    } else { throw MError("Name '" + name + "' not found", [mark]) }
                }
                else {
                    switch peek().type {
                        case C2Token.kwVOID { next(); flags += fvoid }
                        case C2Token.kwBOOL { next(); flags += fbool }
                        case C2Token.kwINT { next(); flags += fint }
                        case C2Token.kwLONG { next(); flags += flong }
                        case C2Token.kwCHAR { next(); flags += fchar }
                        case C2Token.kwSHORT { next(); flags += fshort }
                        else = errorKind("typename")
                    }
                    type = switch flags {
                        case fvoid = Type.void
                        case fint = Type.int
                        case flong; case flong + fint; case flong + flong = Type.long
                        case fbool = Type.bool
                        case fchar = Type.char
                        case fshort; case fshort + fint = Type.short
                        case 0 = errorKind("typename")
                        else = throw MError("Invalid type", [mark])
                    }
                }
            }
        }
        (type, attr)
    }

    private def declspecEnum(self) {
        expect(C2Token.kwENUM)
        val optTag = if at(C2Token.tIDENT) { null(next().stringValue) } else { null }
        if consume('{') {
            var nextValue = 0
            while not consume('}') {
                val mark = mark()
                val name = next().stringValue
                val value = if consume('=') { intConstExpr() } else { nextValue }
                nextValue = value + 1
                val ec = EnumConstant(mark, name, value)
                scope.addEnumConstant(ec)
                if not consume(',') { assert('}') }
            }
        }
    }

    private def declspecDerived(self): Type {
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
            val derived = if val taggable = optTaggable {
                when taggable {
                    case derived(s) {
                        if s.isUnion() == isUnion { s } else {
                            throw MError(
                                "Conflicting taggable kind", [mark, taggable.mark])
                        }
                    }
                    else = throw MError(
                        "Conflicting taggable kind", [mark, taggable.mark])
                }
            } else {
                val s = Type.Derived(mark, isUnion, optTag)
                scope.addTaggable(s)
                s
            }
            if at('{') { derivedDecl(derived, isUnion) }
            derived
        } else {
            # When no tag is provided, assume a derived body always follows
            val derived = Type.Derived(mark, isUnion, optTag)
            derivedDecl(derived, isUnion)
            derived
        }
    }

    private def derivedDecl(self, derived: Type.Derived, isUnion: Bool) {
        if derived.isComplete() {
            throw MError("Duplicate derived definition", [mark(), derived.mark])
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
                    val member = Type.Derived.Member(memberMark, memberName, memberType, 0)
                    currentSize = Math.max(currentSize, member.type.size())
                    derived.members.add(member)
                } else {
                    currentSize = currentSize.roundUp(memberType.alignment())
                    val member = Type.Derived.Member(memberMark, memberName, memberType, currentSize)
                    currentSize += member.type.size()
                    derived.members.add(member)
                }
            }
        }
        derived._alignment = currentAlignment
        derived._size = currentSize.roundUp(currentAlignment)
    }

    private def declarator(self, var type: Type): Tuple[Mark, String, Type] {
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

    private def abstractDeclarator(self, var type: Type): Type {
        while consume('*') {
            type = type.ptrOf()
        }

        if consume('(') {
            val savedStartI = i
            abstractDeclarator(type) # skip the part inside the parens for now
            expect(')')

            # parse the suffix first
            type = typeSuffix(type)
            val savedEndI = i

            # go back and parse the part we skipped
            i = savedStartI
            val result = abstractDeclarator(type)

            # go back to the point after the suffix
            i = savedEndI

            result
        } else {
            typeSuffix(type)
        }
    }

    private def typeSuffix(self, var type: Type): Type {
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
            if consume(']') {
                typeSuffix(type).arrayOf(-1)
            } else {
                val len = intConstExpr()
                expect(']')
                typeSuffix(type).arrayOf(len)
            }
        } else {
            type
        }
    }

    private def typename(self): Type {
        abstractDeclarator(declspec())
    }

    # ========================================================================
    # statements
    # ========================================================================

    private def stmt(self): Stmt {
        val labels: List[String] = []
        while at(C2Token.tIDENT) and atOffset(':', 1) {
            labels.add(next().stringValue)
            next()
        }
        val stmt = stmtWithoutLabels()
        if labels { stmt.labels = labels }
        stmt
    }

    private def stmtWithoutLabels(self): Stmt {
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
                var inits: List[Stmt] = []
                var cond = eb.int(mark, -1)
                var incr = eb.int(mark, -1)
                var then = eb.nop(mark)
                val vars = locals.scoped(() -> {
                    inits = if not consume(';') { declOrStmt() } else { [] }
                    cond = if at(';') { eb.int(mark, 1) } else { expr() }
                    expect(';')
                    incr = if at(')') { eb.int(mark, 0) } else { expr() }
                    expect(')')
                    then = stmt()
                })
                eb.for_(mark, vars, inits, cond, incr, then)
            }
            case C2Token.kwWHILE {
                next()
                expect('(')
                val cond = expr()
                expect(')')
                val then = stmt()
                eb.while_(mark, cond, then)
            }
            case C2Token.kwBREAK {
                next()
                expect(';')
                eb.break_(mark)
            }
            case C2Token.kwCONTINUE {
                next()
                expect(';')
                eb.continue_(mark)
            }
            case C2Token.kwSWITCH {
                next()
                val initstmts: List[Stmt] = []
                val bodystmts: List[Stmt] = []
                expect('(')
                val valexpr = expr()
                val tmpvar = locals.addLVar(mark, valexpr.type, newTmpvarname())
                val gettmpvar = eb.getvar(mark, tmpvar)
                initstmts.add(eb.exprStmt(mark, eb.setvar(mark, tmpvar, valexpr)))
                expect(')')
                expect('{')
                var defaultSeen = false
                while not consume('}') {
                    if at(C2Token.kwCASE) {
                        if defaultSeen {
                            throw MError("Case labels cannot come after the default label", [mark])
                        }
                        val label = newTmpvarname()

                        # add the goto statements at the top
                        while consume(C2Token.kwCASE) {
                            val value = intConstExpr()
                            expect(':')
                            initstmts.add(eb.if_(
                                mark,
                                eb.binop(mark, C2Token.tEQ, gettmpvar, eb.int(mark, value)),
                                eb.goto(mark, label),
                                eb.nop(mark)))
                        }

                        # add the label in the body
                        val labelStmt = eb.nop(mark)
                        labelStmt.labels = [label]
                        bodystmts.add(labelStmt)
                    } else if consume(C2Token.kwDEFAULT) {
                        if defaultSeen {
                            throw MError("Only one default label is allowed per switch", [mark])
                        }
                        defaultSeen = true
                        expect(':')
                        val label = newTmpvarname()

                        # add the goto statement at the top
                        initstmts.add(eb.goto(mark, label))

                        # add the label in the body
                        val labelStmt = eb.nop(mark)
                        labelStmt.labels = [label]
                        bodystmts.add(labelStmt)
                    } else {
                        bodystmts.addAll(declOrStmt())
                    }
                }
                if not defaultSeen {
                    # If there's no default label, we should just break if there's no match
                    # add the goto statement at the top
                    initstmts.add(eb.break_(mark))
                }
                bodystmts.add(eb.break_(mark))

                eb.whileEx(
                    mark,
                    eb.int(mark, 1),  # cond
                    eb.int(mark, 0),  # incr
                    eb.block(mark, [], initstmts + bodystmts),

                    # handleContinue
                    # We don't handle continues so that a 'continue' inside the switch body
                    # will refer to a loop that contains the switch, rather than this
                    # pseudo while loop.
                    false)
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
            case C2Token.kwGOTO {
                next()
                val targetLabel = expect(C2Token.tIDENT).stringValue
                expect(';')
                eb.goto(mark, targetLabel)
            }
            else {
                val expr = expr()
                val ret = eb.exprStmt(mark, expr)
                expect(';')
                ret
            }
        }
    }

    private def declOrStmt(self): List[Stmt] {
        if atTypename() and not atOffset(':', 1) { declaration() } else { [stmt()] }
    }

    private def blockInside(self): Tuple[List[Var], List[Stmt]] {
        val stmts: List[Stmt] = []
        expect('{')
        val vars = locals.scoped(() -> {
            while not consume('}') {
                stmts.addAll(declOrStmt())
            }
        })
        (vars, stmts)
    }

    private def block(self): Stmt {
        val mark = mark()
        val (vars, stmts) = blockInside()
        eb.block(mark, vars, stmts)
    }

    private class Initializer {
        val mark: Mark
        val type: Type
        var expr: Expr = ?
        var children: List[Initializer] = ?

        def(mark: Mark, type: Type): Self {
            val self = __malloc(mark, type)
            if type.isArray() {
                Assert(type.len > 0)
                children = []
                for i = 0; i < type.len; i++ {
                    children.add(Self(mark, type.base))
                }
            }
            self
        }
    }

    private union InitDesg {
        case lvar(Var)
        case subscr(InitDesg, Int)
    }

    private def initializer2(self, init: Initializer) {
        if init.type.isArray() {
            expect('{')
            for i = 0; i < init.type.len and not at('}'); i++ {
                if i > 0 { expect(',') }
                initializer2(init.children[i])
            }
            expect('}')
        } else {
            init.expr = assign()
        }
    }

    private def initializer(self, type: Type): Initializer {
        val init = Initializer(mark(), type)
        initializer2(init)
        init
    }

    private def initDesgExpr(self, mark: Mark, desg: InitDesg): Expr {
        when desg {
            case lvar(var_) = eb.getvar(var_.mark, var_)
            case subscr(nextDesg, idx) {
                val lhs = initDesgExpr(mark, nextDesg)
                val rhs = eb.int(mark, idx)
                eb.preop(mark, '*', eb.binop(mark, '+', lhs, rhs))
            }
        }
    }

    private def createLvarInit(
            self, mark: Mark, init: Initializer, type: Type, desg: InitDesg): Expr {
        when type {
            case array(at) {
                var expr = eb.int(mark, 0)
                for i = 0; i < init.children.size(); i++ {
                    val desg2 = InitDesg.subscr(desg, i)
                    val rhs = createLvarInit(mark, init.children[i], at.base, desg2)
                    expr = eb.comma(mark, expr, rhs)
                }
                expr
            }
            else {
                if is_set!(init, expr) {
                    val lhs = initDesgExpr(mark, desg)
                    val rhs = init.expr
                    eb.binop(mark, '=', lhs, rhs)
                } else {
                    # a partial initializer was given
                    # TODO: clean this up so that these no-op nodes don't show up at all
                    # TODO: Maybe have a eb.nopExpr() method?
                    eb.int(mark, 0)
                }
            }
        }
    }

    # comments from chibicc:
    # ```
    # A variable definition with an initializer is a shorthand notation
    # for a variable definition followed by assignments. This function
    # generates assignment expressions for an initializer. For example,
    # `int x[2][2] = {{6, 7}, {8, 9}}` is converted to the following
    # expressions:
    #
    #   x[0][0] = 6;
    #   x[0][1] = 7;
    #   x[1][0] = 8;
    #   x[1][1] = 9;
    # ```
    private def lvarInitializer(self, var_: Var): Expr {
        val mark = mark()
        val init = initializer(var_.type)
        val desg = InitDesg.lvar(var_)
        eb.comma(mark,
            eb.initzero(mark, var_),
            createLvarInit(mark, init, var_.type, desg))
    }

    # ========================================================================
    # expressions
    # ========================================================================

    private def expr(self): Expr = exprpr(0)
    private def assign(self): Expr = exprpr(assingPrec)
    private def unary(self): Expr = exprpr(unaryPrec)
    private def cond(self): Expr = exprpr(condPrec - 1)

    private def constExpr(self): BigInt = eval(cond())
    private def intConstExpr(self): Int = Int(constExpr())

    private def eval(self, expr: Expr): BigInt {
        when expr.kind {
            case int; case short; case char = expr.intValue
            case long = expr.bigIntValue
            case intAdd; case longAdd = eval(expr.lhs) + eval(expr.rhs)
            case intSub; case longSub = eval(expr.lhs) - eval(expr.rhs)
            case intMul; case longMul = eval(expr.lhs) * eval(expr.rhs)
            case intDiv; case longDiv = eval(expr.lhs) // eval(expr.rhs)
            case intRem; case longRem = eval(expr.lhs) % eval(expr.rhs)
            case intNeg; case longNeg = -eval(expr.arg)
            case intBitwiseAnd = eval(expr.lhs) & eval(expr.rhs)
            case intBitwiseOr = eval(expr.lhs) | eval(expr.rhs)
            case intBitwiseXor = eval(expr.lhs) ^ eval(expr.rhs)
            case intBitwiseNot = ~eval(expr.arg)
            case intShl = eval(expr.lhs).ilshift(Int(eval(expr.rhs)))
            case intShr = eval(expr.lhs).irshift(Int(eval(expr.rhs)))
            case intEq = BigInt(eval(expr.lhs) == eval(expr.rhs))
            case intNe = BigInt(eval(expr.lhs) != eval(expr.rhs))
            case intLt = BigInt(eval(expr.lhs) < eval(expr.rhs))
            case intLe = BigInt(eval(expr.lhs) <= eval(expr.rhs))
            case cond = BigInt(if eval(expr.arg) { eval(expr.lhs) } else { eval(expr.rhs) })
            case comma = eval(expr.rhs)
            case logicalNot = BigInt(not eval(expr.arg))
            case logicalAnd = BigInt(eval(expr.lhs) and eval(expr.rhs))
            case logicalOr = BigInt(eval(expr.lhs) or eval(expr.rhs))
            case cast = switch expr.type.size() {
                case 1 = 0xFFn & eval(expr.arg)
                case 2 = 0xFFFFn & eval(expr.arg)
                case 4 = 0xFFFFFFFFn & eval(expr.arg)
                case 8 = 0xFFFFFFFFFFFFFFFFn & eval(expr.arg)
                else = throw MError("Cast to " + expr.type + " not supported", [expr.mark])
            }
            else = throw MError(
                "Expected int constant expression but got " + expr.kind, [expr.mark])
        }
    }

    private def exprpr(self, precedence: Int): Expr {
        var expr = atom()
        var tokprec = precof(peek().type)
        while precedence < tokprec {
            val mark = mark()
            switch peek().type {
                case '+';case '-';case '*';case '/';case '%';case ','
                case C2Token.tEQ;case C2Token.tNE
                case '<'; case C2Token.tLE; case '>'; case C2Token.tGE
                case C2Token.tSHL; case C2Token.tSHR
                case '&'; case '|'; case '^'; case C2Token.tAND; case C2Token.tOR {
                    # left associative binops
                    val type = next().type
                    expr = eb.binop(mark, type, expr, exprpr(tokprec))
                }
                case '?' {
                    # conditional operator
                    next()
                    val lhs = expr()
                    expect(':')
                    val rhs = cond()
                    expr = eb.cond(mark, expr, lhs, rhs)
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
                case C2Token.tPLUS_EQ
                case C2Token.tMINUS_EQ
                case C2Token.tSTAR_EQ
                case C2Token.tDIV_EQ
                case C2Token.tREM_EQ
                case C2Token.tAND_EQ
                case C2Token.tOR_EQ
                case C2Token.tXOR_EQ
                case C2Token.tSHL_EQ
                case C2Token.tSHR_EQ {
                    # augmented assignment
                    # (a) op = (b) becomes t=&(a),*t=*t op (b)
                    val augtype = next().type
                    val type: Int = switch augtype {
                        case C2Token.tPLUS_EQ = '+'
                        case C2Token.tMINUS_EQ = '-'
                        case C2Token.tSTAR_EQ = '*'
                        case C2Token.tDIV_EQ = '/'
                        case C2Token.tREM_EQ = '%'
                        case C2Token.tAND_EQ = '&'
                        case C2Token.tOR_EQ = '|'
                        case C2Token.tXOR_EQ = '^'
                        case C2Token.tSHL_EQ = C2Token.tSHL
                        case C2Token.tSHR_EQ = C2Token.tSHR
                    }
                    val rhs = assign()
                    expr = toAugassign(mark, type, expr, rhs)
                }
                case C2Token.tINCR; case C2Token.tDECR {
                    # postfix increment operators
                    # (e)++ becomes p=&(e),v=*p,*p=v+1,v
                    val type = switch next().type {
                        case C2Token.tINCR = '+'
                        case C2Token.tDECR = '-'
                    }
                    val tmppvar = locals.addLVar(mark, expr.type.ptrOf(), newTmpvarname())
                    val tmpvvar = locals.addLVar(mark, expr.type, newTmpvarname())
                    expr = eb.commaSeq(
                        mark,

                        # p = &(expr)
                        eb.setvar(mark, tmppvar, eb.preop(mark, '&', expr)),

                        # v = *p
                        eb.binop(mark, '=',
                            eb.getvar(mark, tmpvvar),
                            eb.preop(mark, '*', eb.getvar(mark, tmppvar))),

                        # *p = v + 1
                        eb.binop(mark, '=',
                            eb.preop(mark, '*', eb.getvar(mark, tmppvar)),
                            eb.binop(mark, type,
                                eb.getvar(mark, tmpvvar),
                                eb.int(mark, 1))),

                        # v
                        eb.getvar(mark, tmpvvar))
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

    private def toAugassign(self, mark: Mark, op: Int, lhs: Expr, rhs: Expr): Expr {
        val t = eb.getvar(mark, locals.addLVar(mark, lhs.type.ptrOf(), newTmpvarname()))
        eb.comma(
            mark,

            # t = &lhs
            eb.binop(mark, '=', t, eb.preop(mark, '&', lhs)),

            # *t = *t op rhs
            eb.binop(mark, '=',
                eb.preop(mark, '*', t),
                eb.binop(mark, op, eb.preop(mark, '*', t), rhs)))
    }

    private def args(self): List[Expr] {
        val args: List[Expr] = []
        expect('(')
        while not consume(')') {
            args.add(assign())
            if not consume(',') { assert(')') }
        }
        args
    }

    private def atom(self): Expr {
        val mark = mark()
        switch peek().type {
            case C2Token.tINT = eb.int(mark, next().intValue)
            case C2Token.tLONG = eb.long(mark, next().bigIntValue)
            case C2Token.tCHAR = eb.char(mark, next().intValue)
            case C2Token.tSTR = eb.str(mark, next().bytesValue)
            case '-'; case '+'; case '&'; case '*'; case '!'; case '~' {
                val type = next().type
                eb.preop(mark, type, unary())
            }
            case C2Token.tINCR; case C2Token.tDECR {
                # prefix increment operators
                # ++(e) becomes p=&(e),*p=v+1,*p
                val type = switch next().type {
                    case C2Token.tINCR = '+'
                    case C2Token.tDECR = '-'
                }
                val arg = unary()
                val tmpvar = locals.addLVar(mark, arg.type.ptrOf(), newTmpvarname())
                eb.commaSeq(
                    mark,

                    # p = &(arg)
                    eb.setvar(mark, tmpvar, eb.preop(mark, '&', arg)),

                    # *p = *p + 1
                    eb.binop(mark, '=',
                        eb.preop(mark, '*', eb.getvar(mark, tmpvar)),
                        eb.binop(mark, type,
                            eb.preop(mark, '*', eb.getvar(mark, tmpvar)),
                            eb.int(mark, 1))),

                    # *p
                    eb.preop(mark, '*', eb.getvar(mark, tmpvar)))
            }
            case '(' {
                next()
                if atTypename() {
                    val type = typename()
                    expect(')')
                    val arg = unary()
                    eb.ecast(arg, type)
                } else if at('{') {
                    val (vars, stmts) = blockInside()
                    expect(')')
                    eb.stmtExpr(mark, vars, stmts)
                } else {
                    val inner = expr()
                    expect(')')
                    inner
                }
            }
            case C2Token.tIDENT {
                val name = next().stringValue
                if val ordinary = scope.getOrNull(name) {
                    when ordinary {
                        case lvar(lvar) = eb.getvar(mark, lvar)
                        case gvar(gvar) = eb.getgvar(mark, gvar)
                        case func(func) = eb.func(mark, func)
                        case enumConstant(ec) = eb.int(mark, ec.value)
                        case typedef(..) = throw MError(
                            "'" + name + "' is a type, not a value", [mark])
                    }
                } else {
                    throw MError("Variable '" + name + "' not found", [mark])
                }
            }
            case C2Token.kwSIZEOF {
                next()
                val save = i
                if consume('(') and atTypename() {
                    val type = typename()
                    expect(')')
                    eb.int(mark, type.size())
                } else {
                    i = save
                    val expr = unary()
                    if not expr.type.isComplete() {
                        throw MError("" + expr.type + " is an incomplete type", [mark])
                    }
                    eb.int(mark, expr.type.size())
                }
            }
            else = errorKind("expression")
        }
    }
}
