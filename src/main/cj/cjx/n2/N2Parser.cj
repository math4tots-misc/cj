package cjx.n2

import cj.Range
import cjx.n2.N2Locals
import cjx.n2.N2Lexer
import cjx.n2.N2IR.Expr
import cjx.n2.N2IR.Type
import cjx.n2.N2IR.Func
import cjx.n2.N2IR.FuncTemplate
import cjx.n2.N2IR.StructTemplate
import cjx.n2.N2IR.Program
import cjx.n2.N2IR.Var
import cjx.n2.N2IR.Struct
import cjx.n2.N2IR.TPat
import cjx.n2.N2Error
import cjx.parser.Mark
import cjx.n2.N2Token
import cjx.parser.ParserMixin

class N2Parser: ParserMixin[N2Token] {
    static val unaryPrec: Int = precof('*') + 5

    def typeOfToken(token: N2Token): Int = token.type
    def nameOfType(type: Int): String = N2Token.typeRepr(type)

    def parseAll(tokens: List[N2Token]): Program {
        val program = Program()
        for pass in [0, 1, 2] {
            parseEx(pass, program, tokens)
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
    var templateArgs: Map[String, Type] = MapOf()

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: N2Token): Mark = token.toMark()
    def errorAt(self, message: String, token: N2Token): NoReturn = errorAtMark(
        message, markAt(token))
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw N2Error(
        message, [mark])
    def id(self): String = expect(N2Token.tID).stringValue
    def qid(self): String {
        var name = id()
        while consume('.') { name = name + "." + id() }
        name
    }

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
            } else if consume(N2Token.kwTYPEDEF) {
                val type = type()
                val name = id()
                if pass < 1 { program.addTypedef(mark, type, name) }
                expectDelim()
            } else if at(N2Token.kwSTRUCT) {
                next()
                val name = id()
                struct_(mark, name, name, null)
            } else if consume(N2Token.kwTEMPLATE) {
                val params = parseJoin('[', ']', ',', () -> id())
                skipDelims()
                if pass < 1 {
                    val ti = i
                    if consume(N2Token.kwSTRUCT) {
                        val name = id()
                        val st = StructTemplate(mark, name, params, ti)
                        program.addStructTemplate(st)
                    } else {
                        tpat() # return type
                        val name = qid()
                        val tpats = parseJoin(
                            '(', ')', ',', () -> { val pat = tpat(); id(); pat })
                        val ft = FuncTemplate(mark, name, params, tpats, ti)
                        program.addFuncTemplate(ft)
                    }
                }
                skipToDelimiter()
            } else if pass < 1 {
                skipToDelimiter()
            } else {
                val type = type()
                val name = qid()
                func(mark, type, name, false)
            }
            skipDelims()
        }
        program
    }

    def param(self): Var {
        val mark = mark()
        val type = type()
        val name = id()
        val init = if consume('=') { null(expr()) } else { null }
        locals.add(mark, type, name, init)
    }

    def params(self): List[Var] = parseJoin('(', ')', ',', () -> param())

    def struct_(self, mark: Mark, name: String, rootName: String, templateArgs: List[Type]?) {
        val native_ = consume(N2Token.kwNATIVE)
        switch pass {
            case 0 {
                val struct_ = Struct(mark, name, native_, rootName, [])
                program.addStruct(struct_)
                skipToDelimiter()
            }
            case 1; case 2 {
                if val tas = templateArgs {
                    val struct_ = Struct(mark, name, native_, rootName, tas)
                    program.addStruct(struct_)
                } else if pass > 1 {
                    skipToDelimiter()
                    return ()
                }
                val struct_ = program.getStruct(name)
                expect('{')
                skipDelims()
                while not consume('}') {
                    val imark = mark()
                    val type = type()
                    val name = id()
                    val index = struct_.fields.size()
                    # TOOD: restrict the sorts of expressions allowed here
                    val init = if consume('=') { null(expr()) } else { null }
                    struct_.addField(Var(mark, type, name, index, init))
                    skipDelims()
                }
            }
        }
    }

    def instantiatedStructName(self, st: StructTemplate, typeArgs: List[Type]): String {
        st.name + "[" + ",".join(typeArgs.map(ta -> ta.repr())) + "]"
    }

    def instantiateStruct(self, imark: Mark, st: StructTemplate, iexprs: List[Expr]): Struct {
        if iexprs.size() != st.templateParams.size() {
            throw N2Error(
                "Expected " + st.templateParams.size() + " args but got " + iexprs.size(),
                [imark])
        }
        val typeArgs = iexprs.map(e -> asTypeLiteral(e))
        val name = instantiatedStructName(st, typeArgs)
        if val struct_ = program.getStructOrNull(name) { return struct_ }

        val savedI = i
        val savedArgs = templateArgs
        val savedLocals = locals

        i = st.i
        templateArgs = Map(Range.upto(iexprs.size()).map(i -> (
            st.templateParams[i], typeArgs[i])).toList())
        locals = N2Locals()

        val tmark = mark()
        expect(N2Token.kwSTRUCT)
        val rootName = id()
        Assert.that(name.startsWith(rootName + "["))
        struct_(tmark, name, rootName, null(typeArgs))

        i = savedI
        templateArgs = savedArgs
        locals = savedLocals

        program.getStruct(name)
    }

    def instantiatedFuncName(self, ft: FuncTemplate, typeArgs: List[Type]): String {
        ft.name + "[" + ",".join(typeArgs.map(ta -> ta.repr())) + "]"
    }

    def instantiateFunc(self, imark: Mark, ft: FuncTemplate, iexprs: List[Expr]): Func {
        if iexprs.size() != ft.templateParams.size() {
            throw N2Error(
                "Expected " + ft.templateParams.size() + " args but got " + iexprs.size(),
                [imark])
        }
        val typeArgs = iexprs.map(e -> asTypeLiteral(e))
        val name = instantiatedFuncName(ft, typeArgs)
        if val func = program.getFuncOrNull(name) { return func }

        val savedI = i
        val savedArgs = templateArgs
        val savedLocals = locals

        i = ft.i
        templateArgs = Map(Range.upto(iexprs.size()).map(i -> (
            ft.templateParams[i], typeArgs[i])).toList())
        locals = N2Locals()

        val tmark = mark()
        val returnType = type()
        Assert.that(name.startsWith(qid() + "[")) # skip root function name
        func(tmark, returnType, name, true)

        i = savedI
        templateArgs = savedArgs
        locals = savedLocals

        program.getFuncOrNull(name).get()
    }

    def func(self, mark: Mark, returnType: Type, name: String, instantiatingTemplate: Bool) {
        locals = N2Locals()
        val nparams = params().size()
        val func = Func(mark, returnType, name, nparams, locals.list)
        if pass < 2 {
            program.addFunc(func)
            skipToDelimiter()
        } else {
            if instantiatingTemplate { program.addFunc(func) }
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
        val markStack = [mark()]
        while repeat {
            val mark = mark()
            switch next().type {
                case '('; case '['; case '{' { depth++; markStack.add(mark) }
                case ')'; case ']'; case '}' { depth--; markStack.pop() }
                case N2Token.tEOF {
                    throw N2Error("Unclosed grouping symbol", [markStack.last()])
                }
                else = ()
            }
            repeat = depth > 0
        }
    }

    def asTypeLiteral(self, expr: Expr): Type {
        Expr.evalType(program, expr)
    }

    def type(self): Type = asTypeLiteral(expr())

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
        case '('; case '['; case '.'
        case N2Token.tINCR; case N2Token.tDECR = 140
        case '*'; case '/'; case '%' = 120
        case '+'; case '-' = 100
        case '<'; case '>'; case N2Token.tLE; case N2Token.tGE = 90
        case N2Token.tEQ; case N2Token.tNE = 80
        case '&' = 70
        case '^' = 60
        case '|' = 50
        case N2Token.tAND = 40
        case N2Token.tOR = 30
        case '=' = 20
        else = -1
    }

    def expr(self): Expr = exprpr(0)

    def exprpr(self, precedence: Int): Expr {
        var expr = atom()
        var tokprec = precof(peek().type)
        while precedence < tokprec {
            val mark = mark()
            switch peek().type {
                case '='           { next(); expr = Expr.assign(mark, expr, exprpr(tokprec - 1)) }
                case '+'           { next(); expr = Expr.add(mark, expr, exprpr(tokprec)) }
                case '-'           { next(); expr = Expr.sub(mark, expr, exprpr(tokprec)) }
                case '*'           { next(); expr = Expr.mul(mark, expr, exprpr(tokprec)) }
                case '/'           { next(); expr = Expr.div(mark, expr, exprpr(tokprec)) }
                case '%'           { next(); expr = Expr.rem(mark, expr, exprpr(tokprec)) }
                case N2Token.tEQ   { next(); expr = Expr.eq(mark, expr, exprpr(tokprec)) }
                case N2Token.tNE   { next(); expr = Expr.ne(mark, expr, exprpr(tokprec)) }
                case N2Token.tLE   { next(); expr = Expr.le(mark, expr, exprpr(tokprec)) }
                case '<'           { next(); expr = Expr.lt(mark, expr, exprpr(tokprec)) }
                case N2Token.tGE   { next(); expr = Expr.le(mark, exprpr(tokprec), expr) }
                case '>'           { next(); expr = Expr.lt(mark, exprpr(tokprec), expr) }
                case N2Token.tAND  { next(); expr = Expr.and_(mark, expr, exprpr(tokprec)) }
                case N2Token.tOR   { next(); expr = Expr.or_(mark, expr, exprpr(tokprec)) }
                case N2Token.tINCR { next(); expr = Expr.incr(mark, expr) }
                case N2Token.tDECR { next(); expr = Expr.decr(mark, expr) }
                case '[' {
                    val iexprs = parseJoin('[', ']', ',', () -> expr())
                    if iexprs.isEmpty() {
                        val itemType = asTypeLiteral(expr)
                        expr = Expr.type(mark, Type.list(itemType))
                    } else {
                        switch expr.kind {
                            case Expr.kGETFUNCTEMP {
                                val templ = expr.funcTemplate
                                val func = instantiateFunc(expr.mark, templ, iexprs)
                                val args = argsWithParams(func.params, [])
                                expr = Expr.callf(mark, func, args)
                            }
                            case Expr.kGETSTRUCTTEMP {
                                val templ = expr.structTemplate
                                val struct_ = instantiateStruct(expr.mark, templ, iexprs)
                                expr = Expr.type(mark, Type.struct_(struct_))
                            }
                            case Expr.kBOUNDFUNCTEMP {
                                val templ = expr.funcTemplate
                                val func = instantiateFunc(expr.mark, templ, iexprs)
                                val args = argsWithParams(func.params, [expr.arg])
                                expr = Expr.callf(mark, func, args)
                            }
                            else = throw N2Error("Expected template but got " + expr, [expr.mark])
                        }
                    }
                }
                case '(' {
                    switch expr.kind {
                        case Expr.kGETFUNC {
                            val func = expr.func
                            val args = argsWithParams(func.params, [])
                            expr = Expr.callf(mark, func, args)
                        }
                        case Expr.kGETFUNCTEMP {
                            val ft = expr.funcTemplate
                            val args = args()
                            val templArgs = inferTemplateArgs(mark, ft.templateParams, ft.tpats, args)
                            val func = instantiateFunc(
                                mark, ft, templArgs.map(arg -> Expr.type(mark, arg)))
                            expr = Expr.callf(mark, func, args)
                        }
                        case Expr.kBOUNDFUNC {
                            val func = expr.func
                            val receiver = expr.arg
                            val args = argsWithParams(func.params, [receiver])
                            expr = Expr.callf(mark, func, args)
                        }
                        case Expr.kBOUNDFUNCTEMP {
                            val ft = expr.funcTemplate
                            val args = [expr.arg]
                            args.addAll(args())
                            val templArgs = inferTemplateArgs(mark, ft.templateParams, ft.tpats, args)
                            val func = instantiateFunc(
                                mark, ft, templArgs.map(arg -> Expr.type(mark, arg)))
                            expr = Expr.callf(mark, func, args)
                        }
                        case Expr.kTYPE {
                            when expr.ty {
                                case struct_(struct_) {
                                    val args = argsWithParams(struct_.fields, [])
                                    expr = Expr.newstruct(mark, struct_, args)
                                }
                                else = error("" + expr.ty + " is not a callable type")
                            }
                        }
                        else = error(expr.kindName + " is not callable")
                    }
                }
                case '.' {
                    next()
                    if consume('(') {
                        # type assertion
                        val type = type()
                        expect(')')
                        expr = expr.icast(type)
                    } else {
                        val name = id()
                        if expr.type.isMeta() {
                            switch expr.kind {
                                case Expr.kGETSTRUCTTEMP {
                                    val rootName = expr.structTemplate.name + "." + name
                                    if val func = program.getFuncOrNull(rootName) {
                                        expr = Expr.getfunc(mark, func, rootName)
                                    } else if val ft = program.getFuncTemplateOrNull(rootName) {
                                        expr = Expr.getfuncTemplate(mark, ft, rootName)
                                    } else {
                                        error("Method " + rootName + " not found")
                                    }
                                }
                                case Expr.kTYPE {
                                    when expr.ty {
                                        case struct_(struct_) {
                                            if struct_.templateArgs {
                                                throw N2Error(
                                                    "Struct template args are not allowed " +
                                                    "when accessing members (" +
                                                    struct_.name + "." + name + ")", [expr.mark])
                                            }
                                            val rootName = struct_.name + "." + name
                                            if val func = program.getFuncOrNull(rootName) {
                                                expr = Expr.getfunc(mark, func, rootName)
                                            } else if val ft = program.getFuncTemplateOrNull(rootName) {
                                                expr = Expr.getfuncTemplate(mark, ft, rootName)
                                            } else {
                                                error("Method " + rootName + " not found")
                                            }
                                        }
                                        else = error(
                                            "Could not get member (" + expr.ty + "->" + name + ")")
                                    }
                                }
                                else = error("Could not get member (" + name + ")")
                            }
                        } else {
                            val rootTypeName = expr.type.rootName
                            val rootName = rootTypeName + "." + name
                            if val func = program.getFuncOrNull(rootName) {
                                expr = Expr.boundfunc(mark, func, expr, rootName)
                            } else if val ft = program.getFuncTemplateOrNull(rootName) {
                                expr = Expr.boundfuncTemplate(mark, ft, expr, rootName)
                            } else {
                                when expr.type {
                                    case struct_(struct_) {
                                        if val var_ = struct_.getFieldOrNull(name) {
                                            expr = Expr.getfield(mark, expr, struct_, var_)
                                        } else {
                                            error("Member " + name +
                                                " not found for struct " + struct_.name)
                                        }
                                    }
                                    else = error("Member '" + name + "' not found for " + expr.type)
                                }
                            }
                        }
                    }
                }
                else = error("Unhandled operator " + peek().repr())
            }
            tokprec = precof(peek().type)
        }
        expr
    }

    def inferTemplateArgs(
            self,
            mark: Mark,
            tparams: List[String],
            tpats: List[TPat],
            args: List[Expr]): List[Type] {
        if tpats.size() != args.size() {
            throw N2Error("Expected " + tpats.size() + " args but got " + args.size(), [mark])
        }
        val varnames = Set(tparams)
        val map: Map[String, Type] = MapOf()
        val stack: List[Tuple[TPat, Type]] = []
        for i = tpats.size() - 1; i >= 0; i-- {
            stack.add((tpats[i], args[i].type))
        }
        while map.size() < tparams.size() and stack {
            val (tpat, etype) = stack.pop()
            if tpat.name in varnames and tpat.args.isEmpty() {
                map[tpat.name] = etype
            } else if tpat.name == etype.rootName and tpat.args.size() == etype.args.size() {
                val exprargs = etype.args
                for i = tpat.args.size() - 1; i >= 0; i-- {
                    stack.add((tpat.args[i], exprargs[i]))
                }
            }
        }
        if map.size() < tparams.size() {
            IO.println("args = " + args + ", tpats = " + tpats)
            IO.println("map = (" + map + "), tparams = (" + tparams + ")")
            throw N2Error("Could not infer template args", [mark])
        }
        val out: List[Type] = []
        for i = 0; i < tparams.size(); i++ {
            out.add(map[tparams[i]])
        }
        out
    }

    def args(self): List[Expr] = parseJoin('(', ')', ',', () -> expr())

    def argsWithParams(self, params: List[Var], givenArgs: List[Expr]): List[Expr] {
        val mark = mark()
        var nextIndex = givenArgs.size()
        val args: List[Expr?] = givenArgs.map(arg -> null(arg))
        while args.size() < params.size() { args.add(null) }
        expect('(')
        while not consume(')') {
            val pmark = mark()
            val paramIndex = if at(N2Token.tID) and atOffset('=', 1) {
                val paramName = id()
                val pi = findParamIndexFromName(mark, params, paramName)
                expect('=')
                pi
            } else {
                val pi = nextIndex
                nextIndex++
                if pi >= params.size() {
                    throw N2Error("Too many positional arguments", [pmark])
                }
                pi
            }
            val paramName = params[paramIndex].name
            if args[paramIndex].isPresent() {
                throw N2Error("Argument for '" + paramName + "' already specified", [pmark])
            }
            val arg = expr()
            args[paramIndex] = null(arg.icast(params[paramIndex].type))
            if not consume(',') {
                assert(')')
            }
        }
        for i = 0; i < args.size(); i++ {
            val param = params[i]
            if args[i].isEmpty() {
                if val df = param.init {
                    args[i] = null(df)
                } else {
                    throw N2Error("Argument for '" + param.name + "' is not specified", [mark])
                }
            }
        }
        args.map(a -> a.get())
    }

    private def findParamIndexFromName(self, mark: Mark, params: List[Var], name: String): Int {
        for i = 0; i < params.size(); i++ {
            if params[i].name == name {
                return i
            }
        }
        throw N2Error("Parameter for with name '" + name + "' not found", [mark])
    }

    private def getSelfFieldOrNull(self, name: String): Tuple[Var, Struct, Var]? {
        if val selfVar = locals.getOrNull("self") {
            when selfVar.type {
                case struct_(struct_) {
                    if val fieldVar = struct_.getFieldOrNull(name) {
                        null((selfVar, struct_, fieldVar))
                    } else { null }
                }
                else = null
            }
        } else { null }
    }

    private def getSelfFuncOrNull(self, name: String): Tuple[Var, Func]? {
        if val selfVar = locals.getOrNull("self") {
            if val func = program.getFuncOrNull(selfVar.type.rootName + "." + name) {
                null((selfVar, func))
            } else { null }
        } else { null }
    }

    private def getSelfFuncTemplateOrNull(self, name: String): Tuple[Var, FuncTemplate]? {
        if val selfVar = locals.getOrNull("self") {
            if val ft = program.getFuncTemplateOrNull(selfVar.type.rootName + "." + name) {
                null((selfVar, ft))
            } else { null }
        } else { null }
    }

    def atom(self): Expr {
        val mark = mark()
        switch peek().type {
            case '(' { next(); val e = expr(); expect(')'); e }
            case '+' { next(); val e = exprpr(unaryPrec); Expr.pos(mark, e) }
            case '-' { next(); val e = exprpr(unaryPrec); Expr.neg(mark, e) }
            case '[' = Expr.list(mark, parseJoin('[', ']', ',', () -> expr()), null)
            case '{' = block()
            case N2Token.kwNULL {
                next()
                if consume('[') {
                    val innerType = type()
                    expect(']')
                    if tag!(innerType) == tag!(Type, null_) {
                        throw N2Error("null type cannot be nested", [mark])
                    }
                    Expr.type(mark, Type.null_(innerType))
                } else if consume('(') {
                    val inner = expr()
                    expect(')')
                    Expr.nullwrap(mark, inner)
                } else {
                    Expr.nullexpr(mark)
                }
            }
            case N2Token.tID {
                val name = next().stringValue
                if val var_ = locals.getOrNull(name) {
                    Expr.getvar(mark, var_)
                } else if val (selfVar, struct_, fieldVar) = getSelfFieldOrNull(name) {
                    Expr.getfield(mark, Expr.getvar(mark, selfVar), struct_, fieldVar)
                } else if val (selfVar, func) = getSelfFuncOrNull(name) {
                    Expr.boundfunc(mark, func, Expr.getvar(mark, selfVar), name)
                } else if val (selfVar, funcTemplate) = getSelfFuncTemplateOrNull(name) {
                    Expr.boundfuncTemplate(mark, funcTemplate, Expr.getvar(mark, selfVar), name)
                } else if val type = templateArgs.getOrNull(name) {
                    Expr.type(mark, type)
                } else if val func = program.getFuncOrNull(name) {
                    Expr.getfunc(mark, func, name)
                } else if val funcTemplate = program.getFuncTemplateOrNull(name) {
                    Expr.getfuncTemplate(mark, funcTemplate, name)
                } else if val structTemplate = program.getStructTemplateOrNull(name) {
                    Expr.getstructTemplate(mark, structTemplate)
                } else if val value = program.getConstOrNull(name) {
                    Expr.int(mark, value)
                } else if val type = program.getTypeOrNull(name) {
                    Expr.type(mark, type)
                } else {
                    throw N2Error("Name '" + name + "' not found", [mark])
                }
            }
            case N2Token.tINT = Expr.int(mark, next().intValue)
            case N2Token.tSTRING = Expr.str(mark, next().stringValue)
            case N2Token.tMACROID {
                val name = next().stringValue
                val args = args()
                Expr.macro(mark, program, name, args)
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
            case N2Token.kwAUTO {
                next()
                val name = id()
                expect('=')
                val init = expr()
                val vartype = init.type
                val var_ = locals.add(mark, vartype, name, null(init))
                expectDelim()
                Expr.declvar(mark, var_)
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
            val init = if consume('=') { null(expr()) } else { null }
            val var_ = locals.add(mark, type, name, init)
            exprs.add(Expr.declvar(mark, var_))
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

    def tpat(self): TPat {
        val mark = mark()
        val name = id()
        val bracketPresent = at('[')
        val args = if bracketPresent { parseJoin('[', ']', ',', () -> tpat()) } else { [] }
        var tpat = if args or not bracketPresent { TPat(mark, name, args) } else {
            TPat(mark, "list", [TPat(mark, name, [])])
        }
        while at('[') {
            val amark = mark()
            expect('[')
            expect(']')
            tpat = TPat(amark, "list", [tpat])
        }
        tpat
    }
}
