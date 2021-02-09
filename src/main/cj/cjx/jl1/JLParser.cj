package cjx.jl1

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
        val interfaces: List[JLAstType] = []
        if consume(':') {
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
        JLAstClass(mark, comment, modifiers, isInterface, shortName, interfaces, members)
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
                val args: List[JLAstType] = []
                if at('[') and not atOffset(']', 1) {
                    expect('[')
                    var repeat = true
                    while repeat and not consume(']') {
                        args.add(parseType())
                        if not consume(',') {
                            repeat = false
                            expect(']')
                        }
                    }
                    Assert.that(args)
                }
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
        val modifiers = parseModifiers()
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
        expect(':')
        val type = parseType()
        JLAstField(mark, comment, modifiers, name, type)
    }

    def parseMethod(self, comment: Nullable[String], modifiers: List[String]): JLAstMethod {
        val mark = mark
        expect(JLToken.kwDEF)
        val name = parseId()
        val parameters = parseParameters()
        val returnType = if consume(':') { parseType() } else {
            JLAstType(mark, JLAstType.Data.void())
        }
        val body: Nullable[JLAstExpr] = (
            if consume('=') { null(parseExpression()) }
            else if at('{') { null(parseBlock()) }
            else { null })
        JLAstMethod(mark, comment, modifiers, name, parameters, returnType, body)
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
            expr = switch peek().type {
                case '+' = {
                    next()
                    mkop(
                        mark, JLAstExpr.Operator.add(), expr,
                        parseExpressionWithPrecedence(tokenPrecedence + 1))
                }
                case '-' = {
                    next()
                    mkop(
                        mark, JLAstExpr.Operator.sub(), expr,
                        parseExpressionWithPrecedence(tokenPrecedence + 1))
                }
                case '.' = {
                    next()
                    val name = parseId()
                    if at('(') {
                        val args = parseArgs()
                        JLAstExpr(mark, JLAstExpr.Data.callinstance(expr, name, args))
                    } else {
                        JLAstExpr(mark, JLAstExpr.Data.getfield(expr, name))
                    }
                }
                case '=' = {
                    next()
                    val valexpr = parseExpression()
                    JLAstExpr(mark, when expr.data {
                        case getvar(name) = JLAstExpr.Data.setvar(name, valexpr)
                        case getstatic(clsname, fname) = (
                            JLAstExpr.Data.setstatic(clsname, fname, valexpr))
                        case getfield(owner, name) = JLAstExpr.Data.setfield(owner, name, valexpr)
                        else = throw JLError("The left hand side is not assignable", [mark])
                    })
                }
                else = {
                    throw JLError(
                        "expression operator TODO " + JLToken.typeRepr(peek().type),
                        [mark])
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
            case '@' = {
                next()
                val name = parseId()
                val nullableOp = switch name {
                    case "add" = null(JLAstExpr.Operator.add())
                    else = null
                }
                if null(op) = nullableOp {
                    val args = parseArgs()
                    JLAstExpr(mark, JLAstExpr.Data.operation(op, args))
                } else {
                    switch name {
                        case "callstatic"
                        case "callvirtual"
                        case "callinterface" = {
                            val kind = name["call".size():]
                            expect('(')
                            val type = parseType()
                            expect(',')
                            val className = parseString()
                            expect(',')
                            val methodName = parseString()
                            expect(',')
                            val descriptor = parseString()
                            var repeat = true
                            val args: List[JLAstExpr] = []
                            while repeat {
                                if not consume(',') {
                                    repeat = false
                                } else if not at(')') {
                                    args.add(parseExpression())
                                }
                            }
                            expect(')')
                            JLAstExpr(mark, JLAstExpr.Data.calljava(
                                kind, type, className, methodName, descriptor, args))
                        }
                        else = throw JLError("Unrecognized operator " + name, [mark])
                    }
                }
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
                val className = parseTypeId()
                expect('.')
                val memberName = parseId()
                if at('(') {
                    val args = parseArgs()
                    JLAstExpr(mark, JLAstExpr.Data.callstatic(className, memberName, args))
                } else {
                    JLAstExpr(mark, JLAstExpr.Data.getstatic(className, memberName))
                }
            }
            else = throw JLError("Expected expression", [mark])
        }
    }

    def parseString(self): String = translateStringLiteral(mark, next().text)

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

    private def parseArgs(self): List[JLAstExpr] {
        expect('(')
        val list: List[JLAstExpr] = []
        var repeat = true
        while repeat and not consume(')') {
            list.add(parseExpression())
            if not consume(',') {
                expect(')')
                repeat = false
            }
        }
        list
    }
}
