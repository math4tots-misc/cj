package cjx.jl1

import cjx.jl1.JLIRMetaVal
import cjx.jl1.JLAstMetaExpr
import cjx.jl1.JLAstTemplateArgument
import cjx.jl1.JLAstTemplateParameter
import cjx.jl1.JLAstField
import cjx.jl1.JLAstExpr
import cjx.jl1.JLAstLocal
import cjx.jl1.JLAstMethod
import cjx.jl1.JLLexer
import cj.Error
import cjx.jl1.JLAstType
import cjx.jl1.JLAstClass
import cjx.jl1.JLAstImport
import cj.StringBuilder
import cjx.jl1.JLError
import cjx.jl1.JLAstFile
import cjx.jl1.JLMark
import cjx.jl1.JLToken

@derive(new)
class JLParser {

    static val combineOperators: Set[JLAstExpr.Operator] = Set(
        JLAstExpr.Operator.add(),
        JLAstExpr.Operator.sub(),
        JLAstExpr.Operator.mul(),
        JLAstExpr.Operator.div(),
        JLAstExpr.Operator.rem(),
        JLAstExpr.Operator.and_(),
        JLAstExpr.Operator.or_(),
        JLAstExpr.Operator.logicalAnd(),
        JLAstExpr.Operator.logicalOr(),
    )

    ## Maps token -> (is-right-associative, ast-operator)
    static val binopTable: Map[Int, Tuple[Bool, JLAstExpr.Operator]] = Map(
        '+': (false, JLAstExpr.Operator.add()),
        '-': (false, JLAstExpr.Operator.sub()),
        '*': (false, JLAstExpr.Operator.mul()),
        '/': (false, JLAstExpr.Operator.div()),
        '%': (false, JLAstExpr.Operator.rem()),
        '&': (false, JLAstExpr.Operator.and_()),
        '|': (false, JLAstExpr.Operator.or_()),
        '^': (false, JLAstExpr.Operator.xor()),
        JLToken.tLSHIFT: (false, JLAstExpr.Operator.shl()),
        JLToken.tRSHIFT: (false, JLAstExpr.Operator.shr()),
        JLToken.tRSHIFTU: (false, JLAstExpr.Operator.shru()),
        JLToken.tPOWER: (true, JLAstExpr.Operator.pow()),
        '<': (false, JLAstExpr.Operator.lt()),
        '>': (false, JLAstExpr.Operator.gt()),
        JLToken.tLE: (false, JLAstExpr.Operator.le()),
        JLToken.tGE: (false, JLAstExpr.Operator.ge()),
        JLToken.tEQ: (false, JLAstExpr.Operator.eq()),
        JLToken.tNE: (false, JLAstExpr.Operator.ne()),
        JLToken.kwAND: (false, JLAstExpr.Operator.logicalAnd()),
        JLToken.kwOR: (false, JLAstExpr.Operator.logicalOr()),
    )

    static val unopTable: Map[Int, Tuple[Int, JLAstExpr.Operator]] = Map(
        '-': (getTokenPrecedence('*') + 5, JLAstExpr.Operator.neg()),
        JLToken.kwNOT: (
            getTokenPrecedence(JLToken.kwAND) - 5,
            JLAstExpr.Operator.logicalNot()),
    )

    def parse(filename: String, string: String): JLAstFile {
        val tokens = JLLexer.lex(filename, string)
        val parser = JLParser(filename, tokens)
        parser.parseFile()
    }

    val filename: String
    val tokens: List[JLToken]
    var i = 0

    def __get_mark(self): JLMark = peek().toMark(filename)
    def peek(self): JLToken = tokens[i]
    def next(self): JLToken = {
        val token = tokens[i]
        i = i + 1
        token
    }
    def at(self, type: Int): Bool = peek().type == type
    def atOffset(self, type: Int, offset: Int): Bool = {
        val j = i + offset
        j < tokens.size() and tokens[j].type == type
    }
    def expect(self, type: Int): JLToken {
        if not at(type) {
            throw JLError(
                "Expected " + JLToken.typeRepr(type) + " but got " +
                JLToken.typeRepr(peek().type),
                [mark])
        }
        next()
    }
    def consume(self, type: Int): Bool = if at(type) { next(); true } else { false }

    def parseId(self): String {
        expect(JLToken.tID).text
    }

    def parseTypeId(self): String {
        expect(JLToken.tTYPEID).text
    }

    def skipDelimiters(self) {
        while at('\n') or at(';') {
            next()
        }
    }

    def expectDelimiters(self) {
        if not (at('\n') or at(';') or at('}') or at(JLToken.tEOF)) {
            throw JLError("Expected delimiter", [mark])
        }
        skipDelimiters()
    }

    def parseFile(self): JLAstFile {
        val mark = mark

        expect(JLToken.kwPACKAGE)
        val packageName = parsePackageName()
        expectDelimiters()

        val imports: List[JLAstImport] = []
        while at(JLToken.kwIMPORT) {
            imports.add(parseImport())
        }

        val classes: List[JLAstClass] = []
        while not at(JLToken.tEOF) {
            val comment = parseComment()
            skipDelimiters()
            val modifiers = parseModifiers()
            classes.add(parseClass(comment, modifiers))
        }

        JLAstFile(mark, packageName, imports, classes)
    }

    def parseImport(self): JLAstImport {
        val mark = mark
        expect(JLToken.kwIMPORT)
        val packageName = parsePackageName()
        expect('.')
        val shortName = parseTypeId()
        val alias = if consume(JLToken.kwAS) { parseTypeId() } else { shortName }
        expectDelimiters()
        JLAstImport(mark, packageName + "." + shortName, alias)
    }

    def parsePackageName(self): String {
        val sb = StringBuilder()
        sb.add(parseId())
        while at('.') and atOffset(JLToken.tID, 1) {
            expect('.')
            sb.add(".")
            sb.add(parseId())
        }
        sb.toString()
    }

    def parseComment(self): Nullable[String] {
        if at(JLToken.tCOMMENT) {
            null(next().text)
        } else {
            null
        }
    }

    def parseAnnotationStyleModifiers(self): List[String] {
        val modifiers: List[String] = []
        while consume('@') {
            val nullableName = switch peek().type {
                case (JLToken.tID) = switch peek().text {
                    case "test" = null(next().text)
                    else = null
                }
                else = null
            }
            if null(name) = nullableName {
                modifiers.add(name)
            } else {
                throw JLError("Expected @modifier name", [mark])
            }
            expectDelimiters()
        }
        modifiers
    }

    def parseModifiers(self): List[String] {
        val modifiers: List[String] = []
        while peek().type in JLToken.modifierKeywordTypes {
            modifiers.add(JLToken.keywordString(next().type))
        }
        modifiers
    }

    def parseClass(self, comment: Nullable[String], modifiers: List[String]): JLAstClass {
        val mark = mark
        val isInterface = if consume(JLToken.kwINTERFACE) { true } else {
            expect(JLToken.kwCLASS)
            false
        }
        val shortName = parseTypeId()
        val templateParameters = parseTemplateParameters()
        val superClass = if consume(JLToken.kwEXTENDS) { null(parseType()) } else { null }
        val interfaces: List[JLAstType] = []
        if consume(JLToken.kwIMPLEMENTS) {
            skipDelimiters()
            interfaces.add(parseType())
            skipDelimiters()
            while consume(',') {
                skipDelimiters()
                interfaces.add(parseType())
                skipDelimiters()
            }
        }
        skipDelimiters()
        val members: List[JLAstClass.Member] = []
        expect('{')
        skipDelimiters()
        while not consume('}') {
            members.add(parseMember())
            skipDelimiters()
        }
        expectDelimiters()
        JLAstClass(
            mark,
            comment,
            modifiers,
            isInterface,
            shortName,
            templateParameters,
            superClass,
            interfaces,
            members)
    }

    def parseTemplateParameter(self): JLAstTemplateParameter {
        val mark = mark
        val modifiers = parseModifiers()
        if at(JLToken.tID) {
            val name = parseId()
            expect(':')
            expect(JLToken.kwINT)
            JLAstTemplateParameter(mark, modifiers, name, JLAstTemplateParameter.Kind.int())
        } else {
            val name = parseTypeId()
            JLAstTemplateParameter(mark, modifiers, name, JLAstTemplateParameter.Kind.type())
        }
    }

    def parseTemplateParameters(self): List[JLAstTemplateParameter] = {
        if at('[') {
            parseJoin('[', ']', ',', () -> parseTemplateParameter())
        } else {
            []
        }
    }

    def parseTemplateArg(self): JLAstTemplateArgument {
        val mark = mark
        if at('-') or at(JLToken.tINT) {
            val neg = consume('-')
            val rawValue = translateInt(mark, expect(JLToken.tINT).text)
            val value = if neg { -rawValue } else { rawValue }
            JLAstTemplateArgument(mark, JLAstTemplateArgument.Data.int(value))
        } else {
            val type = parseType()
            JLAstTemplateArgument(mark, JLAstTemplateArgument.Data.type(type))
        }
    }

    def parseTemplateArgs(self): List[JLAstTemplateArgument] = parseJoin(
        '[', ']', ',', () -> parseTemplateArg())

    def parseJoin[T](self, open: Int, close: Int, sep: Int, inner: Fn[T]): List[T] {
        expect(open)
        var loop = true
        val list: List[T] = []
        while loop and not at(close) {
            list.add(inner.call())
            if not consume(sep) {
                loop = false
            }
        }
        expect(close)
        list
    }

    def parseType(self): JLAstType {
        var mark = mark
        var type = switch peek().type {
            case (JLToken.kwVOID) = { next(); JLAstType(mark, JLAstType.Data.void()) }
            case (JLToken.kwBOOL) = { next(); JLAstType(mark, JLAstType.Data.bool()) }
            case (JLToken.kwBYTE) = { next(); JLAstType(mark, JLAstType.Data.byte()) }
            case (JLToken.kwCHAR) = { next(); JLAstType(mark, JLAstType.Data.char()) }
            case (JLToken.kwSHORT) = { next(); JLAstType(mark, JLAstType.Data.short()) }
            case (JLToken.kwINT) = { next(); JLAstType(mark, JLAstType.Data.int()) }
            case (JLToken.kwLONG) = { next(); JLAstType(mark, JLAstType.Data.long()) }
            case (JLToken.kwFLOAT) = { next(); JLAstType(mark, JLAstType.Data.float()) }
            case (JLToken.kwDOUBLE) = { next(); JLAstType(mark, JLAstType.Data.double()) }
            else = {
                val name = parseTypeId()
                val args = if at('[') and not atOffset(']', 1) { parseTemplateArgs() } else { [] }
                JLAstType(mark, JLAstType.Data.klass(name, args))
            }
        }
        mark = self.mark
        while consume('[') {
            expect(']')
            type = JLAstType(mark, JLAstType.Data.array(type))
            mark = self.mark
        }
        type
    }

    def parseMember(self): JLAstClass.Member {
        val comment = parseComment()
        skipDelimiters()
        val modifiers = parseAnnotationStyleModifiers()
        modifiers.addAll(parseModifiers())
        switch peek().type {
            case (JLToken.kwVAR)
            case (JLToken.kwVAL) = JLAstClass.Member.field(parseField(comment, modifiers))
            case (JLToken.kwDEF) = JLAstClass.Member.method(parseMethod(comment, modifiers))
            case (JLToken.kwCLASS)
            case (JLToken.kwINTERFACE) = JLAstClass.Member.klass(parseClass(comment, modifiers))
            else = throw JLError("Expected class member", [mark])
        }
    }

    def parseField(self, comment: Nullable[String], modifiers: List[String]): JLAstField {
        val mark = mark
        if consume(JLToken.kwVAR) {
            modifiers.add("var")
        } else {
            expect(JLToken.kwVAL)
        }
        val name = parseId()
        val type = if consume(':') { null(parseType()) } else { null }
        val init = if consume('=') { null(parseExpression()) } else { null }
        expectDelimiters()
        JLAstField(mark, comment, modifiers, name, type, init)
    }

    def parseMethod(self, comment: Nullable[String], modifiers: List[String]): JLAstMethod {
        val mark = mark
        expect(JLToken.kwDEF)
        val name = if at('(') {
            "jl$new"
        } else {
            parseId()
        }
        val templateParameters = parseTemplateParameters()
        val parameters = parseParameters()
        val returnType = if consume(':') { parseType() } else {
            JLAstType(mark, JLAstType.Data.void())
        }
        val body: Nullable[JLAstExpr] = (
            if consume('=') { null(parseExpression()) }
            else if at('{') { null(parseBlock()) }
            else { null })
        JLAstMethod(
            mark, comment, modifiers, name, templateParameters, parameters, returnType, body)
    }

    def parseParameters(self): List[JLAstLocal] {
        expect('(')
        val list: List[JLAstLocal] = []
        var more = if at(JLToken.kwTHIS) {
            val mark = mark
            expect(JLToken.kwTHIS)
            list.add(JLAstLocal(mark, [], "this", null, null))
            if consume(',') {
                true
            } else {
                expect(')')
                false
            }
        } else {
            true
        }
        while more and not consume(')') {
            val mark = mark
            val modifiers = parseModifiers()
            if consume(JLToken.kwVAR) {
                modifiers.add("var")
            }
            val name = parseId()
            expect(':')
            val type = parseType()
            list.add(JLAstLocal(mark, modifiers, name, null(type), null))
            if not consume(',') {
                more = false
                expect(')')
            }
        }
        list
    }

    def parseBlock(self): JLAstExpr {
        val mark = mark
        val exprs: List[JLAstExpr] = []
        expect('{')
        skipDelimiters()
        while not consume('}') {
            exprs.add(parseExpression())
            expectDelimiters()
        }
        JLAstExpr(mark, JLAstExpr.Data.block(exprs))
    }

    def getTokenPrecedence(tokenType: Int): Int = switch tokenType {
        case '='
        case (JLToken.tPLUS_EQ)
        case (JLToken.tMINUS_EQ)
        case (JLToken.tSTAR_EQ)
        case (JLToken.tREM_EQ) = 20
        case ':' = 30
        case (JLToken.kwOR) = 40
        case (JLToken.kwAND) = 50
        case '<'
        case '>'
        case (JLToken.tEQ)
        case (JLToken.tNE)
        case (JLToken.tGE)
        case (JLToken.tLE)
        case (JLToken.kwIS)
        case (JLToken.kwIN)
        case (JLToken.kwNOT) = 60
        case '|' = 70
        case '^' = 80
        case '&' = 90
        case (JLToken.tLSHIFT)
        case (JLToken.tRSHIFT)
        case (JLToken.tRSHIFTU) = 100
        case '+'
        case '-' = 110
        case '*'
        case '/'
        case '%'
        case (JLToken.tTRUNCDIV) = 120
        case (JLToken.tPOWER) = 130
        case (JLToken.tPLUSPLUS)
        case (JLToken.tMINUSMINUS)
        case '.'
        case '['
        case '?' = 140
        else = -1
    }

    def parseExpression(self): JLAstExpr = parseExpressionWithPrecedence(0)

    def mkop(self, mark: JLMark, op: JLAstExpr.Operator, lhs: JLAstExpr, rhs: JLAstExpr): JLAstExpr {
        if op in combineOperators and isOp(lhs, op) {
            when lhs.data {
                case operation(operator, args) = args.add(rhs)
                else = throw Error("FUBAR")
            }
            lhs
        } else {
            JLAstExpr(mark, JLAstExpr.Data.operation(op, [lhs, rhs]))
        }
    }

    def isOp(expr: JLAstExpr, operator: JLAstExpr.Operator): Bool {
        when expr.data {
            case operation(op, args) = op == operator
            else = false
        }
    }

    def parseExpressionWithPrecedence(self, precedence: Int): JLAstExpr {
        var expr = parseAtomExpression()
        var tokenPrecedence = getTokenPrecedence(peek().type)
        while tokenPrecedence >= precedence {
            val mark = mark
            val toktype = peek().type
            expr = switch toktype {
                case '.' = {
                    next()
                    val name = parseId()
                    if at('(') {
                        val args = [expr]
                        args.addAll(parseArgs())
                        JLAstExpr(mark, JLAstExpr.Data.callinstance(name, args))
                    } else {
                        JLAstExpr(mark, JLAstExpr.Data.getfield(expr, name))
                    }
                }
                case '[' = {
                    next()
                    val index = parseExpression()
                    expect(']')
                    JLAstExpr(mark, JLAstExpr.Data.operation(
                        JLAstExpr.Operator.getitem(),
                        [expr, index]))
                }
                case '=' = {
                    next()
                    val valexpr = parseExpression()
                    val nullableData = when expr.data {
                        case getvar(name) = null(JLAstExpr.Data.setvar(name, valexpr))
                        case getstatic(clsname, fname) = null(
                            JLAstExpr.Data.setstatic(clsname, fname, valexpr))
                        case getfield(owner, name) = null(
                            JLAstExpr.Data.setfield(owner, name, valexpr))
                        case operation(operator, args) = when operator {
                            case getitem = {
                                Assert.equal(args.size(), 2)
                                null(JLAstExpr.Data.operation(
                                    JLAstExpr.Operator.setitem(),
                                    [args[0], args[1], valexpr]))
                            }
                            else = null
                        }
                        else = null
                    }
                    if null(data) = nullableData {
                        JLAstExpr(mark, data)
                    } else {
                        throw JLError("The left hand side is not assignable", [mark])
                    }
                }
                case (JLToken.tPLUS_EQ)
                case (JLToken.tPLUSPLUS)
                case (JLToken.tMINUSMINUS) = {
                    val (op, valexpr) = switch next().type {
                        case (JLToken.tPLUSPLUS) = (
                            JLAstExpr.Operator.add(), JLAstExpr(mark, JLAstExpr.Data.int(1)))
                        case (JLToken.tMINUSMINUS) = (
                            JLAstExpr.Operator.add(), JLAstExpr(mark, JLAstExpr.Data.int(-1)))
                        case (JLToken.tPLUS_EQ) = (JLAstExpr.Operator.add(), parseExpression())
                        else = throw JLError("FUBAR op switch", [mark])
                    }
                    val nullableData = when expr.data {
                        case getvar(name) = null(JLAstExpr.Data.augvar(name, op, valexpr))
                        else = null
                    }
                    if null(data) = nullableData {
                        JLAstExpr(mark, data)
                    } else {
                        throw JLError("The left hand side is not augassignable", [mark])
                    }
                }
                else = {
                    if null((isRightAssociative, operator)) = binopTable.getOrNull(toktype) {
                        next()
                        mkop(mark, operator, expr, parseExpressionWithPrecedence(
                            tokenPrecedence + if isRightAssociative { 0 } else { 1 }))
                    } else {
                        throw JLError(
                            "expression operator TODO " + JLToken.typeRepr(peek().type),
                            [mark])
                    }
                }
            }
            tokenPrecedence = getTokenPrecedence(peek().type)
        }
        expr
    }

    def parseAtomExpression(self): JLAstExpr {
        val mark = mark
        switch peek().type {
            case '{' = parseBlock()
            case '(' = {
                expect('(')
                val inner = parseExpression()
                expect(')')
                inner
            }
            case '[' = {
                val args = parseJoin('[', ']', ',', () -> parseExpression())
                JLAstExpr(mark, JLAstExpr.Data.list(args))
            }
            case '@' = {
                next()
                JLAstExpr(mark, JLAstExpr.Data.meta(parseMetaExpr()))
            }
            case (JLToken.kwTRUE) = {
                next()
                JLAstExpr(mark, JLAstExpr.Data.bool(true))
            }
            case (JLToken.kwFALSE) = {
                next()
                JLAstExpr(mark, JLAstExpr.Data.bool(false))
            }
            case (JLToken.tINT) = {
                JLAstExpr(mark, JLAstExpr.Data.int(translateInt(mark, next().text)))
            }
            case (JLToken.tDOUBLE) = {
                JLAstExpr(mark, JLAstExpr.Data.double(translateDouble(mark, next().text)))
            }
            case (JLToken.kwVAR)
            case (JLToken.kwVAL) = {
                val modifiers = if consume(JLToken.kwVAR) { ["var"] } else {
                    expect(JLToken.kwVAL)
                    []
                }
                val name = parseId()
                val type = if consume(':') { null(parseType()) } else { null }
                expect('=')
                val init = null(parseExpression())
                JLAstExpr(mark, JLAstExpr.Data.declvar(JLAstLocal(
                    mark, modifiers, name, type, init)))
            }
            case (JLToken.kwIF) = parseIf()
            case (JLToken.kwWHILE) = {
                next()
                val cond = parseExpression()
                val body = parseBlock()
                JLAstExpr(mark, JLAstExpr.Data.while_(cond, body))
            }
            case (JLToken.kwFOR) = {
                next()
                if at(';') or (at(JLToken.tID) and atOffset('=', 1)) {
                    val init = if not at(';') {
                        val name = parseId()
                        expect('=')
                        val initexpr = parseExpression()
                        null(JLAstExpr(mark, JLAstExpr.Data.declvar(
                            JLAstLocal(mark, ["var"], name, null, null(initexpr)))))
                    } else { null }
                    expect(';')
                    val cond = if not at(';') { null(parseExpression()) } else { null }
                    expect(';')
                    val incr = if not at('{') { null(parseExpression()) } else { null }
                    val body = parseBlock()
                    JLAstExpr(mark, JLAstExpr.Data.classicFor(init, cond, incr, body))
                } else {
                    val name = parseId()
                    expect(JLToken.kwIN)
                    val container = parseExpression()
                    val body = parseBlock()
                    JLAstExpr(mark, JLAstExpr.Data.for_(name, container, body))
                }
            }
            case (JLToken.tID) = {
                val name = parseId()
                if at('(') {
                    val args = parseArgs()
                    JLAstExpr(mark, JLAstExpr.Data.callname(name, args))
                } else {
                    JLAstExpr(mark, JLAstExpr.Data.getvar(name))
                }
            }
            case (JLToken.tSTRING) = {
                JLAstExpr(mark, JLAstExpr.Data.string(parseString()))
            }
            case (JLToken.tTYPEID) = {
                val classtype = parseType()
                if at('(') {
                    val args = parseArgs()
                    JLAstExpr(mark, JLAstExpr.Data.calltype(classtype, args))
                } else {
                    expect('.')
                    if consume(JLToken.kwNEW) {
                        val args = parseArgs()
                        JLAstExpr(mark, JLAstExpr.Data.callnew(classtype, args))
                    } else {
                        val memberName = parseId()
                        if at('(') {
                            val args = parseArgs()
                            JLAstExpr(mark, JLAstExpr.Data.callstatic(classtype, memberName, args))
                        } else {
                            JLAstExpr(mark, JLAstExpr.Data.getstatic(classtype, memberName))
                        }
                    }
                }
            }
            else = {
                if null((precedence, operator)) = unopTable.getOrNull(peek().type) {
                    next()
                    val arg = parseExpressionWithPrecedence(precedence)
                    JLAstExpr(mark, JLAstExpr.Data.operation(operator, [arg]))
                } else {
                    throw JLError("Expected expression", [mark])
                }
            }
        }
    }

    def parseMetaExpr(self): JLAstMetaExpr {
        val mark = mark
        JLAstMetaExpr(mark, switch peek().type {
            case '{' = JLAstMetaExpr.Data.expr(parseBlock())
            case '(' = {
                next()
                if consume(JLToken.kwDO) {
                    val ret = JLAstMetaExpr.Data.expr(parseExpression())
                    expect(')')
                    ret
                } else {
                    val name = parseNameForMetaFunc()
                    val args: List[JLAstMetaExpr] = []
                    while not consume(')') {
                        args.add(parseMetaExpr())
                    }
                    JLAstMetaExpr.Data.apply(name, args)
                }
            }
            case '[' = {
                next()
                val args: List[JLAstMetaExpr] = []
                while not consume(']') {
                    args.add(parseMetaExpr())
                }
                JLAstMetaExpr.Data.apply("list", args)
            }
            case (JLToken.kwTRUE) = {
                next()
                JLAstMetaExpr.Data.value(JLIRMetaVal.number(1))
            }
            case (JLToken.kwFALSE) = {
                next()
                JLAstMetaExpr.Data.value(JLIRMetaVal.number(0))
            }
            case (JLToken.kwVOID)
            case (JLToken.kwBOOL)
            case (JLToken.kwBYTE)
            case (JLToken.kwCHAR)
            case (JLToken.kwSHORT)
            case (JLToken.kwINT)
            case (JLToken.kwLONG)
            case (JLToken.kwFLOAT)
            case (JLToken.kwDOUBLE)
            case (JLToken.tTYPEID) = JLAstMetaExpr.Data.type(parseType())
            case (JLToken.tID) = JLAstMetaExpr.Data.name(parseId())
            case (JLToken.kwNEW) = { next(); JLAstMetaExpr.Data.name("new") }
            case (JLToken.tINT) = JLAstMetaExpr.Data.value(
                JLIRMetaVal.number(translateInt(mark, next().text)))
            case (JLToken.tDOUBLE) = JLAstMetaExpr.Data.value(
                JLIRMetaVal.number(translateDouble(mark, next().text)))
            case (JLToken.tSTRING) = JLAstMetaExpr.Data.value(
                JLIRMetaVal.string(parseString()))
            else = throw JLError("Expected meta expression", [mark])
        })
    }

    def parseNameForMetaFunc(self): String = switch peek().type {
        case (JLToken.tID) = parseId()
        case (JLToken.kwIF)
        case (JLToken.kwAND)
        case (JLToken.kwOR) = JLToken.keywordString(next().type)
        else = throw JLError("Expected meta function name", [mark])
    }

    def parseString(self): String = translateStringLiteral(mark, expect(JLToken.tSTRING).text)

    def parseIf(self): JLAstExpr {
        val mark = mark
        expect(JLToken.kwIF)
        val cond = parseExpression()
        val body = parseBlock()
        val other = if consume(JLToken.kwELSE) {
            null(if at(JLToken.kwIF) {
                parseIf()
            } else {
                parseBlock()
            })
        } else { null }
        JLAstExpr(mark, JLAstExpr.Data.if_(cond, body, other))
    }

    private def translateInt(mark: JLMark, input: String): Int {
        if null(i) = input.parseInt() {
            i
        } else {
            throw JLError("Unrecognized int literal " + input, [mark])
        }
    }

    private def translateDouble(mark: JLMark, input: String): Double {
        if null(f) = input.parseDouble() {
            f
        } else {
            throw JLError("Unrecognized double literal " + input, [mark])
        }
    }

    private def translateStringLiteral(mark: JLMark, input: String): String {
        val sb = StringBuilder()
        Assert.equal(input.charAt(0), '"')
        Assert.equal(input.charAt(input.size() - 1), '"')
        var i = 1
        while i + 1 < input.size() {
            switch input.charAt(i) {
                case '\\' = {
                    i++
                    sb.add(switch input.charAt(i) {
                        case 'n' = "\n"
                        case 't' = "\t"
                        case '\'' = "\'"
                        case '"' = "\""
                        else = throw JLError(
                            "Unrecognized escape: " + input.charAt(i).repr(), [mark])
                    })
                }
                else = sb.add(input.charAt(i).toString())
            }
            i += input.charAt(i).size()
        }
        sb.toString()
    }

    private def parseArgs(self): List[JLAstExpr] = parseJoin('(', ')', ',', () -> parseExpression())
}
