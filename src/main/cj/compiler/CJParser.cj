package compiler

import compiler.CJLexer
import compiler.CJAst
import compiler.CJAst.Local
import compiler.CJAst.Expr
import compiler.CJAst.ExprData as ED
import cj.StringBuilder
import compiler.CJItemKind
import compiler.CJModifier
import cjx.parser.MError
import cjx.parser.Mark
import compiler.CJToken

class CJParser {
    private static val normalExpressionPrecedence: Int = getTokenPrecedence('=') + 5
    private static val indexExpressionPrecedence: Int = getTokenPrecedence(':') + 5
    private static val logicalNotPrecedence: Int = getTokenPrecedence(CJToken.tEQ) + 5
    private static val unaryOpPrecedence: Int = getTokenPrecedence('*') + 5

    private val path: String
    private val tokens: List[CJToken]
    private var i = 0

    def parse(filename: String, contents: String): CJAst.File {
        val tokens = CJLexer.lex(filename, contents)
        val parser = Self(filename, tokens)
        parser.parseFile()
    }

    def parseExpression(filename: String, contents: String): Expr {
        val tokens = CJLexer.lex(filename, contents)
        val parser = Self(filename, tokens)
        val expr = parser.parseExprPr(0)
        if not parser.at(CJToken.tEOF) {
            throw parser.ekind("EOF")
        }
        expr
    }

    private def __get_mark(self): Mark = { val t = peek(); Mark(path, t.line, t.column) }
    private def peek(self): CJToken = tokens[i]
    private def next(self): CJToken { i = i + 1; tokens[i - 1] }
    private def at(self, type: Int): Bool = peek().type == type
    private def atOffset(self, type: Int, offset: Int): Bool {
        val j = i + offset
        j < tokens.size() and tokens[j].type == type
    }
    private def assert(self, type: Int) {
        if not at(type) {
            throw etype(type)
        }
    }
    private def expect(self, type: Int): CJToken { assert(type); next() }
    private def consume(self, type: Int): Bool {
        if at(type) { next(); true } else { false }
    }
    private def etype(self, type: Int): MError = ekind(CJToken.typeRepr(type))
    private def ekind(self, kind: String): MError = MError(
        "Expected " + kind + " but got " + CJToken.typeRepr(peek().type), [mark])
    private def expectDelimiters(self) {
        if not at(';') and not at('}') and not at('\n') {
            throw ekind("delimiter")
        }
        skipDelimiters()
    }
    private def skipDelimiters(self) {
        while at(';') or at('\n') {
            next()
        }
    }
    private def parseId(self): String = expect(CJToken.tID).text
    private def parseTypeId(self): String = expect(CJToken.tTYPEID).text
    private def parseTypeIdEx(self): String {
        val sb = StringBuilder()
        sb.add(parseTypeId())
        while at('.') and atOffset(CJToken.tTYPEID, 1) {
            expect('.')
            sb.add(".")
            sb.add(parseTypeId())
        }
        sb.toString()
    }
    private def parseOptSeq[T](self, start: Int, sep: Int, el: Fn[T]): List[T] {
        val list = List[T].empty()
        if consume(start) {
            list.add(el.call())
            while consume(sep) {
                list.add(el.call())
            }
        }
        list
    }
    private def parseJoinOpt[T](self, open: Int, close: Int, sep: Int, el: Fn[T]): List[T] {
        if at(open) { parseJoin(open, close, sep, el) } else { [] }
    }
    private def parseJoin[T](self, open: Int, close: Int, sep: Int, el: Fn[T]): List[T] {
        expect(open)
        val list: List[T] = []
        while not consume(close) {
            list.add(el.call())
            if not consume(sep) {
                assert(close)
            }
        }
        list
    }
    private def lit2char(rawText: String, mark: Mark): Char {
        switch rawText {
            case "'\\''" = '\''
            case "'\\\"'" = '"'
            case "'\\\\'" = '\\'
            case "'\\b'" = '\b'
            case "'\\f'" = '\f'
            case "'\\r'" = '\r'
            case "'\\t'" = '\t'
            case "'\\n'" = '\n'
            case "'\\0'" = '\0'
            else = {
                val chars = rawText.iter().toList()
                if chars.size() == 3 and chars[0] == '\'' and chars[2] == '\'' {
                    chars[1]
                } else {
                    throw MError("Could not convert character literal: " + rawText, [mark])
                }
            }
        }
    }
    private def lit2str(rawText: String, mark: Mark): String {
        if rawText.startsWith("r\"\"\"") {
            Assert.that(rawText.size() >= 7 and rawText.endsWith("\"\"\""))
            rawText[4:rawText.size() - 3]
        } else if rawText.startsWith("r\"") {
            Assert.that(rawText.size() >= 3 and rawText.endsWith("\""))
            rawText[1:rawText.size() - 1]
        } else if rawText.startsWith("\"\"\"") {
            Assert.that(rawText.size() >= 6 and rawText.endsWith("\"\"\""))
            litchars2str(rawText, rawText[3:rawText.size() - 3].iter(), mark)
        } else {
            Assert.that(
                rawText.size() >= 2 and rawText.startsWith("\"") and rawText.endsWith("\""))
            litchars2str(rawText, rawText[1:rawText.size() - 1].iter(), mark)
        }
    }
    private def litchars2str(rawText: String, chars: Iterator[Char], mark: Mark): String {
        val sb = StringBuilder()
        var escape = false
        for ch in chars {
            if escape {
                sb.char(switch ch {
                    case '\'' = '\''
                    case '\"' = '"'
                    case '\\' = '\\'
                    case 'n' = '\n'
                    case 't' = '\t'
                    case 'r' = '\r'
                    case 'f' = '\f'
                    case '0' = '\0'
                    else = {
                        throw MError(
                            "Unrecognized escape " + ch.repr() + " (in " + rawText + ")", [mark])
                    }
                })
                escape = false
            } else if ch == '\\' {
                escape = true
            } else {
                sb.char(ch)
            }
        }
        sb.toString()
    }
    private def parseFile(self): CJAst.File {
        val mark = mark
        expect(CJToken.kwPACKAGE)
        val packageName = parsePackageName()
        expectDelimiters()
        val imports = List[CJAst.Import].empty()
        while at(CJToken.kwIMPORT) {
            imports.add(parseImport())
        }
        val comment = parseComment()
        val annotations = parseAnnotations()
        val modifiers = parseModifiers()
        val item = parseItem(comment, annotations, modifiers)
        if not at(CJToken.tEOF) {
            throw ekind("EOF")
        }
        CJAst.File(mark, packageName, imports, item)
    }
    private def parseItem(
            self,
            comment: String?,
            annotations: List[CJAst.Annotation],
            modifiers: List[CJModifier]): CJAst.Item {
        val kind = parseItemKind()
        val mark = mark
        val shortName = parseTypeId()
        val typeParameters = parseTypeParameters(true)
        val traitDeclarations = parseTraitDeclarations()
        skipDelimiters()
        expect('{')
        skipDelimiters()
        val members = List[CJAst.Member].empty()
        while not consume('}') {
            parseMember(members)
        }
        expectDelimiters()
        CJAst.Item(
            mark,
            comment,
            annotations,
            modifiers,
            kind,
            shortName,
            typeParameters,
            traitDeclarations,
            members)
    }
    private def parseEnum(self, members: List[CJAst.Member]) {
        expect(CJToken.kwENUM)
        expect('{')
        skipDelimiters()
        var nextValue = 0
        while not consume('}') {
            val m = mark
            val name = parseId()
            val value = if consume('=') { parseInt() } else { nextValue }
            members.add(CJAst.Member.field(CJAst.Field(
                m,
                null,
                [],
                [CJModifier.static_],
                false,
                name,
                null(CJAst.Type(m,"Int", [])),
                null(Expr(m, ED.int(value))),
            )))
            nextValue = value + 1
            skipDelimiters()
        }
        skipDelimiters()
    }
    private def parseInt(self): Int = Int(expect(CJToken.tINT).text)
    private def parseMember(self, members: List[CJAst.Member]) {
        val comment = parseComment()
        val annotations = parseAnnotations()
        val modifiers = parseModifiers()
        switch peek().type {
            case CJToken.kwVAL
            case CJToken.kwVAR {
                members.add(CJAst.Member.field(parseField(comment, annotations, modifiers)))
            }
            case CJToken.kwCASE {
                members.add(CJAst.Member.case_(parseCase(comment, annotations, modifiers)))
            }
            case CJToken.kwIF
            case CJToken.kwDEF {
                members.add(CJAst.Member.method(parseMethod(comment, annotations, modifiers)))
            }
            case CJToken.kwCLASS
            case CJToken.kwTRAIT
            case CJToken.kwUNION {
                members.add(CJAst.Member.item(parseItem(comment, annotations, modifiers)))
            }
            case CJToken.kwENUM = parseEnum(members)
            else = throw ekind("var, val, def, if, class, trait or union")
        }
    }
    private def parseField(
            self,
            comment: String?,
            annotations: List[CJAst.Annotation],
            modifiers: List[CJModifier]): CJAst.Field {
        val mutable = if consume(CJToken.kwVAR) { true } else { expect(CJToken.kwVAL); false }
        val mark = mark
        val name = parseId()
        val (type, init) = if consume(':') {
            val type = parseType()
            val init: Expr? = if consume('=') {
                if consume('?') {
                    annotations.add(CJAst.Annotation(mark, "lateinit", []))
                    null
                } else {
                    null(parseExpr())
                }
            } else { null }
            (null(type), init)
        } else {
            expect('=')
            (null, null(parseExpr()))
        }
        expectDelimiters()
        CJAst.Field(mark, comment, annotations, modifiers, mutable, name, type, init)
    }
    private def parseCase(
            self,
            comment: String?,
            annotations: List[CJAst.Annotation],
            modifiers: List[CJModifier]): CJAst.Case {
        expect(CJToken.kwCASE)
        val mark = mark
        val name = parseId()
        val types = parseJoinOpt('(', ')', ',', () -> parseType())
        expectDelimiters()
        CJAst.Case(mark, comment, annotations, modifiers, name, types)
    }
    private def parseMethod(
            self,
            comment: String?,
            annotations: List[CJAst.Annotation],
            modifiers: List[CJModifier]): CJAst.Method {
        val conditions = List[CJAst.TypeCondition].empty()
        if consume(CJToken.kwIF) {
            conditions.add(parseTypeCondition())
            while consume(CJToken.kwAND) {
                conditions.add(parseTypeCondition())
            }
        }
        skipDelimiters()
        expect(CJToken.kwDEF)
        val mark = mark
        val name = if at(CJToken.tID) { parseId() } else { "__new" }
        val typeParameters = parseTypeParameters(false)
        val parameters = parseParameters()
        val returnType = if consume(':') { null(parseType()) } else { null }
        val body = if consume('=') { null(parseExpr()) } else if at('{') {
            null(parseBlock()) } else { null }
        expectDelimiters()
        CJAst.Method(
            mark,
            comment,
            annotations,
            modifiers,
            conditions,
            name,
            typeParameters,
            parameters,
            returnType,
            body)
    }
    private def parseParameters(self): List[Local] = (
        parseJoin('(', ')', ',', () -> parseParameter()))
    private def parseParameter(self): Local {
        val mutable = consume(CJToken.kwVAR)
        val mark = mark
        val name = parseId()
        val type = if not at(':') and name == "self" {
            CJAst.Type(mark, "Self", [])
        } else {
            expect(':')
            parseType()
        }
        Local(mark, mutable, name, null(type))
    }
    private def parseComment(self): String? {
        if at(CJToken.tCOMMENT) {
            val ret = null(expect(CJToken.tCOMMENT).text)
            expectDelimiters()
            ret
        } else { null }
    }
    private def parseModifiers(self): List[CJModifier] {
        val modifiers: List[CJModifier] = []
        var repeat = true
        while repeat {
            switch peek().type {
                case CJToken.kwNATIVE { next(); modifiers.add(CJModifier.native_) }
                case CJToken.kwSTATIC { next(); modifiers.add(CJModifier.static_) }
                case CJToken.kwPUBLIC { next(); modifiers.add(CJModifier.public_) }
                case CJToken.kwPRIVATE { next(); modifiers.add(CJModifier.private_) }
                case CJToken.kwASYNC { next(); modifiers.add(CJModifier.async_) }
                else = { repeat = false }
            }
        }
        modifiers
    }
    private def parseItemKind(self): CJItemKind {
        switch peek().type {
            case CJToken.kwCLASS { next(); CJItemKind.class_ }
            case CJToken.kwUNION { next(); CJItemKind.union_ }
            case CJToken.kwTRAIT { next(); CJItemKind.trait_ }
            else = throw ekind("class, union or trait")
        }
    }
    private def parsePackageName(self): String {
        val sb = StringBuilder()
        sb.add(parseId())
        while at('.') and atOffset(CJToken.tID, 1) {
            expect('.')
            sb.add(".")
            sb.add(parseId())
        }
        sb.toString()
    }
    private def parseImport(self): CJAst.Import {
        expect(CJToken.kwIMPORT)
        val mark = mark
        val (name, alias) = parseFullItemNameAndAlias()
        expectDelimiters()
        CJAst.Import(mark, name, alias)
    }
    private def parseFullItemNameAndAlias(self): Tuple[String, String] {
        val packageName = parsePackageName()
        expect('.')
        var shortName = parseTypeId()
        var name = packageName + "." + shortName
        while consume('.') {
            shortName = parseTypeId()
            name = name + "." + shortName
        }
        val alias = if consume(CJToken.kwAS) { parseTypeId() } else { shortName }
        (name, alias)
    }
    private def parseAnnotations(self): List[CJAst.Annotation] {
        val list: List[CJAst.Annotation] = []
        while consume('@') {
            list.add(parseAnnotation())
            skipDelimiters()
        }
        list
    }
    private def parseAnnotationIdPart(self): String {
        switch peek().type {
            case CJToken.tINT
            case CJToken.tDOUBLE
            case CJToken.tTYPEID = next().text
            else = parseId()
        }
    }
    private def parseAnnotationId(self): String {
        var name = parseAnnotationIdPart()
        while consume('.') {
            name = name + "." + parseAnnotationIdPart()
        }
        name
    }
    private def parseAnnotation(self): CJAst.Annotation {
        val mark = mark
        val name = parseAnnotationId()
        val args = parseJoinOpt('(', ')', ',', () -> parseAnnotation())
        CJAst.Annotation(mark, name, args)
    }
    private def parseTypeParameters(self, itemLevel: Bool): List[CJAst.TypeParameter] {
        parseJoinOpt('[', ']', ',', () -> parseTypeParameter(itemLevel))
    }
    private def parseTypeParameter(self, itemLevel: Bool): CJAst.TypeParameter {
        val annotations = parseAnnotations()
        val mark = mark
        val name = parseTypeId()
        if consume('?') {
            annotations.add(CJAst.Annotation(mark, "nullable", []))
        }
        val traits = parseOptSeq(':', '&', () -> parseTrait())
        CJAst.TypeParameter(mark, itemLevel, annotations, name, traits)
    }
    private def parseTrait(self): CJAst.Trait {
        val mark = mark
        val name = parseTypeIdEx()
        val args = parseTypeArgs()
        CJAst.Trait(mark, name, args)
    }
    private def parseType(self): CJAst.Type {
        val mark = mark
        val name = parseTypeIdEx()
        val args = parseTypeArgs()
        val type = CJAst.Type(mark, name, args)
        val qmark = self.mark
        if consume('?') {
            CJAst.Type(qmark, "Nullable", [type])
        } else { type }
    }
    private def parseTypeArgs(self): List[CJAst.Type] {
        parseJoinOpt('[', ']', ',', () -> parseType())
    }
    private def parseTraitDeclarations(self): List[CJAst.TraitDeclaration] {
        val decls: List[CJAst.TraitDeclaration] = []
        skipDelimiters()
        if consume(':') {
            skipDelimiters()
            decls.add(parseTraitDeclaration())
            skipDelimiters()
            while consume(',') {
                skipDelimiters()
                decls.add(parseTraitDeclaration())
                skipDelimiters()
            }
        }
        decls
    }
    private def parseTraitDeclaration(self): CJAst.TraitDeclaration {
        val mark = mark
        val trait_ = parseTrait()
        val conditions = parseOptSeq(CJToken.kwIF, CJToken.kwAND, () -> parseTypeCondition())
        CJAst.TraitDeclaration(mark, trait_, conditions)
    }
    private def parseTypeCondition(self): CJAst.TypeCondition {
        val mark = mark
        val variableName = parseTypeId()
        val traits = parseOptSeq(':', '&', () -> parseTrait())
        CJAst.TypeCondition(mark, variableName, traits)
    }
    private def getTokenPrecedence(tokenType: Int): Int = switch tokenType {
        case '='
        case CJToken.tPLUSPLUS
        case CJToken.tMINUSMINUS
        case CJToken.tPLUS_EQ
        case CJToken.tMINUS_EQ
        case CJToken.tSTAR_EQ
        case CJToken.tREM_EQ = 20
        case ':' = 30
        case CJToken.kwOR = 40
        case CJToken.kwAND = 50
        case '<'
        case '>'
        case CJToken.tEQ
        case CJToken.tNE
        case CJToken.tGE
        case CJToken.tLE
        case CJToken.kwIS
        case CJToken.kwIN
        case CJToken.kwNOT = 60
        case '|' = 70
        case '^' = 80
        case '&' = 90
        case CJToken.tLSHIFT
        case CJToken.tRSHIFT
        case CJToken.tRSHIFTU = 100
        case '+'
        case '-' = 110
        case '*'
        case '/'
        case '%'
        case CJToken.tTRUNCDIV = 120
        case CJToken.tPOWER = 130
        case '.'
        case '['
        case '?' = 140
        else = -1
    }
    private def parseExpr(self): Expr = parseExprPr(normalExpressionPrecedence)
    private def parseIndexExpr(self): Expr = parseExprPr(indexExpressionPrecedence)
    private def parseExprPr(self, precedence: Int): Expr {
        var expr = parseAtom()
        var tokenPrecedence = getTokenPrecedence(peek().type)
        while tokenPrecedence >= precedence {
            val opMark = self.mark
            switch peek().type {
                case '.' {
                    next()
                    val methodMark = mark
                    if consume(CJToken.kwAWAIT) {
                        expr = Expr(methodMark, ED.await_(expr))
                    } else {
                        val name = parseId()
                        if atMethodArgsStart(i) {
                            val typeArgs = parseTypeArgs()
                            val args = [expr]
                            args.addAll(parseArgs())
                            expr = Expr(methodMark, ED.call(null, name, typeArgs, args))
                        } else {
                            expr = Expr(methodMark, ED.getfield(expr, name))
                        }
                    }
                }
                case '[' {
                    next()
                    if consume(':') {
                        val index = parseIndexExpr()
                        expect(']')
                        expr = Expr(opMark, ED.call(null, "__sliceTo", [], [expr, index]))
                    } else {
                        val index = parseIndexExpr()
                        if consume(':') {
                            if (consume(']')) {
                                expr = Expr(
                                    opMark, ED.call(null, "__sliceFrom", [], [expr, index]))
                            } else {
                                val limit = parseIndexExpr()
                                expect(']')
                                expr = Expr(opMark, ED.call(null, "__slice", [], [
                                    expr, index, limit]))
                            }
                        } else {
                            val allArgs = [expr, index]
                            while consume(',') {
                                allArgs.add(parseIndexExpr())
                            }
                            expect(']')
                            if consume('=') {
                                # TODO: This should really be handled in parseExprPr in case '='
                                val valexpr = parseExpr()
                                allArgs.add(valexpr)
                                expr = Expr(opMark, ED.call(null, "__setitem", [], allArgs))
                            } else {
                                expr = Expr(opMark, ED.call(null, "__getitem", [], allArgs))
                            }
                        }
                    }
                }
                case ':' {
                    # a : b is syntactic sugar for (a, b)
                    next()
                    val second = parseExpr()
                    expr = Expr(opMark, ED.tuple([expr, second]))
                }
                case '=' {
                    next()
                    val valexpr = parseExprPr(tokenPrecedence + 1)
                    expr = Expr(opMark, when expr.data {
                        case getvar(name) = ED.setvar(name, valexpr)
                        case getfield(owner, name) = ED.setfield(owner, name, valexpr)
                        case getstatic(owner, name) = ED.setstatic(owner, name, valexpr)
                        else = throw MError("Left hand side is not assignable", [opMark])
                    })
                }
                case CJToken.tPLUS_EQ; case CJToken.tMINUS_EQ;
                case CJToken.tSTAR_EQ; case CJToken.tREM_EQ;
                case CJToken.tPLUSPLUS; case CJToken.tMINUSMINUS {
                    val tokenType = next().type
                    val kind = switch tokenType {
                        case CJToken.tPLUSPLUS
                        case CJToken.tPLUS_EQ = CJAst.AugKind.add
                        case CJToken.tMINUSMINUS
                        case CJToken.tMINUS_EQ = CJAst.AugKind.subtract
                        case CJToken.tSTAR_EQ = CJAst.AugKind.multiply
                        case CJToken.tREM_EQ = CJAst.AugKind.remainder
                    }
                    val valexpr = switch tokenType {
                        case CJToken.tPLUSPLUS
                        case CJToken.tMINUSMINUS = Expr(opMark, ED.int(1))
                        else = parseExprPr(tokenPrecedence + 1)
                    }
                    expr = Expr(opMark, when expr.data {
                        case getvar(name) = ED.augvar(name, kind, valexpr)
                        case getfield(owner, name) = ED.augfield(owner, name, kind, valexpr)
                        case getstatic(owner, name) = ED.augstatic(owner, name, kind, valexpr)
                        else = throw MError("Left hand side is not aug-assignable", [opMark])
                    })
                }
                case CJToken.kwAND {
                    next()
                    val right = parseExprPr(tokenPrecedence + 1)
                    expr = Expr(opMark, ED.logicalAnd(expr, right))
                }
                case CJToken.kwOR {
                    next()
                    val right = parseExprPr(tokenPrecedence + 1)
                    expr = Expr(opMark, ED.logicalOr(expr, right))
                }
                case CJToken.kwIS {
                    next()
                    val not_ = consume(CJToken.kwNOT)
                    val rhs = parseExprPr(tokenPrecedence + 1)
                    expr = Expr(opMark, ED.is_(expr, rhs))
                    if not_ { expr = Expr(opMark, ED.logicalNot(expr)) }
                }
                case '+';case '-';case '*';case '/';case '%'
                case '<';case '>';case '|';case '^';case '&'
                case CJToken.tLSHIFT;case CJToken.tRSHIFT
                case CJToken.tRSHIFTU;case CJToken.tPOWER
                case CJToken.tTRUNCDIV;case CJToken.tEQ
                case CJToken.tNE;case CJToken.tLE
                case CJToken.tGE;case CJToken.kwIN
                case CJToken.kwNOT {
                    var logicalNot = false
                    var rightAssociative = false
                    var swap = false
                    val methodName = switch next().type {
                        case '+' = "__add"
                        case '-' = "__sub"
                        case '*' = "__mul"
                        case '/' = "__div"
                        case '%' = "__rem"
                        case '<' = "__lt"
                        case '>' = "__gt"
                        case '|' = "__or"
                        case '^' = "__xor"
                        case '&' = "__and"
                        case CJToken.tLSHIFT = "__lshift"
                        case CJToken.tRSHIFT = "__rshift"
                        case CJToken.tRSHIFTU = "__rshiftu"
                        case CJToken.tPOWER { rightAssociative = true; "__pow" }
                        case CJToken.tTRUNCDIV = "__truncdiv"
                        case CJToken.tEQ = "__eq"
                        case CJToken.tNE { logicalNot = true; "__eq" }
                        case CJToken.tLE = "__le"
                        case CJToken.tGE = "__ge"
                        case CJToken.kwIN { swap = true; "__contains" }
                        case CJToken.kwNOT {
                            expect(CJToken.kwIN)
                            logicalNot = true
                            swap = true
                            "__contains"
                        }
                    }
                    var rhs = parseExprPr(tokenPrecedence + if rightAssociative { 0 } else { 1 })
                    if swap {
                        val tmp = rhs
                        rhs = expr
                        expr = tmp
                    }
                    expr = Expr(mark, ED.call(null, methodName, [], [expr, rhs]))
                    if logicalNot {
                        expr = Expr(mark, ED.logicalNot(expr))
                    }
                }
                else = throw ekind("expression operator (TODO)")
            }
            tokenPrecedence = getTokenPrecedence(peek().type)
        }
        expr
    }
    private def parseAtom(self): Expr {
        val mark = mark
        switch peek().type {
            case '{' = parseBlock()
            case '(' {
                if atLambda() {
                    parseLambda()
                } else if atOffset(')', 1) {
                    next()
                    next()
                    Expr(mark, ED.unit)
                } else {
                    next()
                    val inner = parseExpr()
                    if at(',') {
                        val exprs = [inner] + parseJoin(',', ')', ',', () -> parseExpr())
                        Expr(mark, ED.tuple(exprs))
                    } else {
                        expect(')')
                        inner
                    }
                }
            }
            case '[' {
                val exprs = parseJoin('[', ']', ',', () -> parseExpr())
                Expr(mark, ED.list(exprs))
            }
            case CJToken.kwNULL {
                next()
                val innerType = if consume('[') {
                    val t = parseType()
                    expect(']')
                    null(t)
                } else { null }
                val inner = if consume('(') {
                    val e = parseExpr()
                    expect(')')
                    null(e)
                } else { null }
                Expr(mark, ED.null_(innerType, inner))
            }
            case CJToken.kwTRUE { next(); Expr(mark, ED.bool(true)) }
            case CJToken.kwFALSE { next(); Expr(mark, ED.bool(false)) }
            case CJToken.tCHAR = Expr(mark, ED.char(lit2char(next().text, mark)))
            case CJToken.tINT = Expr(mark, ED.int(Int(next().text)))
            case CJToken.tDOUBLE = Expr(mark, ED.double(Double(next().text)))
            case CJToken.tSTRING = Expr(mark, ED.string(lit2str(next().text, mark)))
            case CJToken.tBIGINT = Expr(mark, ED.bigint(BigInt({
                val text = next().text
                text[:text.size() - 1]
            })))
            case CJToken.tTYPEID {
                val startMark = mark
                val owner = parseType()
                if at('(') {
                    val opmark = self.mark
                    val args = parseArgs()
                    Expr(opmark, ED.call(null(owner), "__new", [], args))
                } else if consume('.') {
                    val opmark = self.mark
                    val name = parseId()
                    if atMethodArgsStart(i) {
                        val typeArgs = parseTypeArgs()
                        val args = parseArgs()
                        Expr(opmark, ED.call(null(owner), name, typeArgs, args))
                    } else {
                        Expr(opmark, ED.getstatic(owner, name))
                    }
                } else {
                    val opmark = mark
                    Expr(opmark, ED.type(owner))
                }
            }
            case CJToken.tID {
                if atLambda() {
                    parseLambda()
                } else if atMethodArgsStart(i + 1) {
                    val opmark = self.mark
                    val methodName = parseId()
                    val typeArgs = parseTypeArgs()
                    val args = parseArgs()
                    Expr(opmark, ED.callname(methodName, typeArgs, args))
                } else {
                    val opmark = self.mark
                    val name = parseId()
                    Expr(opmark, ED.getvar(name))
                }
            }
            case CJToken.tMACROID {
                val opmark = mark
                val name = next().text
                val args = parseArgs()
                Expr(opmark, ED.macro(name, args))
            }
            case CJToken.kwIF {
                next()
                val mutable = consume(CJToken.kwVAR)
                if mutable or consume(CJToken.kwVAL) {
                    val target = parseTarget(mutable)
                    expect('=')
                    val inner = parseExpr()
                    val left = parseBlock()
                    val right = if consume(CJToken.kwELSE) {
                        null(if at(CJToken.kwIF) { parseExpr() } else { parseBlock() })
                    } else { null }
                    Expr(mark, ED.ifNull(target, inner, left, right))
                } else {
                    val condition = parseExpr()
                    val left = parseBlock()
                    val right = if consume(CJToken.kwELSE) {
                        null(if at(CJToken.kwIF) { parseExpr() } else { parseBlock() })
                    } else { null }
                    Expr(mark, ED.if_(condition, left, right))
                }
            }
            case CJToken.kwRETURN {
                next()
                Expr(mark, ED.return_(parseExpr()))
            }
            case CJToken.kwWHILE {
                next()
                val condition = parseExpr()
                val body = parseBlock()
                Expr(mark, ED.while_(condition, body))
            }
            case CJToken.kwFOR {
                next()
                if at(';') or at(CJToken.tID) and atOffset('=', 1) {
                    # c-style for loop -- parse-time syntactic sugar
                    val initpair = if not at(';') {
                        val target = parseTarget(true)
                        expect('=')
                        val init = parseExpr()
                        null((target, init))
                    } else { null }
                    expect(';')
                    val condition = if at(';') { Expr(mark, ED.bool(true)) } else { parseExpr() }
                    expect(';')
                    val incr: Expr? = if at('{') { null } else { null(parseExprPr(0)) }
                    val bodyexprs = parseBlockExprs()
                    if val inc = incr { bodyexprs.add(inc) }
                    val body = Expr(mark, ED.block(bodyexprs))
                    Expr(mark, ED.block(
                        if val (target, init) = initpair {
                            [Expr(mark, ED.decl(target, null, init))]
                        } else { [] } +
                        [Expr(mark, ED.while_(condition, body))]))
                } else {
                    val target = parseTarget(false)
                    expect(CJToken.kwIN)
                    val container = parseExpr()
                    val body = parseBlock()
                    Expr(mark, ED.for_(target, container, body))
                }
            }
            case CJToken.kwNOT {
                next()
                Expr(mark, ED.logicalNot(parseExprPr(logicalNotPrecedence)))
            }
            case '+'; case '-'; case '~' {
                val methodName = switch next().type {
                    case '+' = "__pos"
                    case '-' = "__neg"
                    case '~' = "__invert"
                }
                Expr(mark, ED.call(null, methodName, [], [parseExprPr(unaryOpPrecedence)]))
            }
            case CJToken.kwVAL; case CJToken.kwVAR {
                val mutable = next().type == CJToken.kwVAR
                val opmark = mark
                val target = parseTarget(mutable)
                val decltype = if consume(':') { null(parseType()) } else { null }
                expect('=')
                val init = parseExpr()
                Expr(opmark, ED.decl(target, decltype, init))
            }
            case CJToken.kwWHEN {
                next()
                val target = parseExpr()
                expect('{')
                skipDelimiters()
                val cases = List[CJAst.WhenCase].empty()
                while not at('}') and not at(CJToken.kwELSE) {
                    val patterns = List[Tuple[Mark, String, List[CJAst.Local], Bool]].empty()
                    while at(CJToken.kwCASE) {
                        val caseMark = self.mark
                        expect(CJToken.kwCASE)
                        val caseName = parseId()
                        val decls = List[Local].empty()
                        var trailingArgs = false
                        if consume('(') {
                            while not consume(')') {
                                if consume(CJToken.tDOTDOT) {
                                    trailingArgs = true
                                    assert(')')
                                } else {
                                    val mutable = consume(CJToken.kwVAR)
                                    val varMark = self.mark
                                    val varName = parseId()
                                    decls.add(Local(varMark, mutable, varName, null))
                                    if not consume(',') {
                                        assert(')')
                                    }
                                }
                            }
                        }
                        skipDelimiters()
                        patterns.add((caseMark, caseName, decls, trailingArgs))
                    }
                    val body = if consume('=') { parseExpr() } else { parseBlock() }
                    cases.add(CJAst.WhenCase(patterns, body))
                    expectDelimiters()
                }
                # TODO: actually save the parsed else-cases
                while at(CJToken.kwELSE) and (atOffset('(', 1) or atOffset(CJToken.tID, 1)) {
                    while at(CJToken.kwELSE) and (atOffset('(', 1) or atOffset(CJToken.tID, 1)) {
                        val patterns = List[Tuple[Mark, String?, List[CJAst.Local], Bool]].of()
                        val caseMark = self.mark
                        expect(CJToken.kwELSE)
                        val caseNameVar = if at(CJToken.tID) { null(parseId()) } else { null }
                        val decls = List[Local].empty()
                        var trailingArgs = false
                        if consume('(') {
                            while not consume(')') {
                                if consume(CJToken.tDOTDOT) {
                                    trailingArgs = true
                                    assert(')')
                                } else {
                                    val mutable = consume(CJToken.kwVAR)
                                    val varMark = self.mark
                                    val varName = parseId()
                                    decls.add(Local(varMark, mutable, varName, null))
                                    if not consume(',') {
                                        assert(')')
                                    }
                                }
                            }
                        }
                        skipDelimiters()
                        patterns.add((caseMark, caseNameVar, decls, trailingArgs))
                    }
                    val body = if consume('=') { parseExpr() } else { parseBlock() }
                    # cases.add(CJAst.WhenCase(patterns, body))
                    expectDelimiters()
                }
                val fallback = if consume(CJToken.kwELSE) {
                    null(if consume('=') { parseExpr() } else { parseBlock() })
                } else { null }
                skipDelimiters()
                expect('}')
                Expr(mark, ED.when_(target, cases, fallback))
            }
            case CJToken.kwSWITCH {
                next()
                val target = parseExpr()
                expect('{')
                skipDelimiters()
                val cases = List[CJAst.SwitchCase].empty()
                while not at('}') and not at(CJToken.kwELSE) {
                    expect(CJToken.kwCASE)
                    val valexprs = [parseExpr()]
                    skipDelimiters()
                    while consume(CJToken.kwCASE) {
                        valexprs.add(parseExpr())
                        skipDelimiters()
                    }
                    val body = if consume('=') { parseExpr() } else { parseBlock() }
                    expectDelimiters()
                    cases.add(CJAst.SwitchCase(valexprs, body))
                }
                val fallback = if consume(CJToken.kwELSE) {
                    null(if consume('=') { parseExpr() } else { parseBlock() })
                } else { null }
                skipDelimiters()
                expect('}')
                Expr(mark, ED.switch_(target, cases, fallback))
            }
            case CJToken.kwTHROW { next(); Expr(mark, ED.throw_(parseExpr())) }
            case CJToken.kwTRY {
                next()
                val body = parseBlock()
                val clauses = List[CJAst.Catch].empty()
                while consume(CJToken.kwCATCH) {
                    val target = parseTarget(false)
                    expect(':')
                    val excType = parseType()
                    val clauseBody = parseBlock()
                    clauses.add(CJAst.Catch(target, excType, clauseBody))
                }
                val fin = if consume(CJToken.kwFINALLY) { null(parseBlock()) } else { null }
                Expr(mark, ED.try_(body, clauses, fin))
            }
            else = throw ekind("expression")
        }
    }

    private def atMethodArgsStart(self, i: Int): Bool {
        if i >= tokens.size() { return false }
        switch tokens[i].type {
            case '(' = true
            case '[' {
                val j = indexAfterMatching(i)
                j < tokens.size() and tokens[j].type == '('
            }
            else = false
        }
    }
    private def indexAfterMatching(self, i: Int): Int {
        var j = i + 1
        var depth = 1
        while j < tokens.size() and depth > 0 {
            val token = tokens[j]
            switch token.type {
                case '('; case '{'; case '[' { depth++ }
                case ')'; case '}'; case ']' { depth-- }
                else = ()
            }
            j++
        }
        j
    }
    private def parseArgs(self): List[Expr] = parseJoin('(', ')', ',', () -> parseExpr())
    private def atLambda(self): Bool {
        if at(CJToken.kwASYNC) { return true }
        if at(CJToken.tID) and atOffset(CJToken.tRIGHT_ARROW, 1) { return true }
        if not at('(') { return false }
        val j = indexAfterMatching(i)
        j < tokens.size() and tokens[j].type == CJToken.tRIGHT_ARROW
    }
    private def parseLambda(self): Expr {
        val mark = mark
        val isAsync = consume(CJToken.kwASYNC)
        val parameters = if at(CJToken.tID) {
            val pname = parseId()
            [Local(mark, false, pname, null)]
        } else {
            parseJoin('(', ')', ',', () -> {
                val mutable = consume(CJToken.kwVAR)
                val pmark = self.mark
                val pname = parseId()
                Local(pmark, mutable, pname, null)
            })
        }
        expect(CJToken.tRIGHT_ARROW)
        val body = parseExpr()
        Expr(mark, ED.lambda(isAsync, parameters, body))
    }
    private def parseBlock(self): Expr {
        val mark = mark
        val exprs = parseBlockExprs()
        Expr(mark, ED.block(exprs))
    }
    private def parseBlockExprs(self): List[Expr] {
        expect('{')
        skipDelimiters()
        val exprs = List[Expr].empty()
        while not consume('}') {
            exprs.add(parseExprPr(0))
            expectDelimiters()
        }
        exprs
    }
    private def parseTarget(self, mutable: Bool): CJAst.DeclTarget {
        val mark = mark
        switch peek().type {
            case CJToken.tID {
                val name = parseId()
                CJAst.DeclTarget(mark, CJAst.DeclTargetData.name(Local(
                    mark, mutable, name, null)))
            }
            case '(' {
                val subtargets = parseJoin('(', ')', ',', () -> parseTarget(mutable))
                CJAst.DeclTarget(mark, CJAst.DeclTargetData.tuple(subtargets))
            }
            else = throw MError("Expected declaration target", [mark])
        }
    }
}
