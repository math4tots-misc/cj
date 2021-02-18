package compiler

import compiler.CJAst
import compiler.CJAst.Expr
import compiler.CJAst.ExprData as ED
import cj.StringBuilder
import compiler.CJItemKind
import compiler.CJModifier
import compiler.CJError
import compiler.CJMark
import compiler.CJToken

class CJParser {
    private static val normalExpressionPrecedence: Int = getTokenPrecedence('=') + 5
    private static val indexExpressionPrecedence: Int = getTokenPrecedence(':') + 5
    private static val logicalNotPrecedence: Int = getTokenPrecedence(CJToken.tEQ) + 5
    private static val unaryOpPrecedence: Int = getTokenPrecedence('*') + 5

    private val path: String
    private val tokens: List[CJToken]
    private var i = 0

    private def __get_mark(self): CJMark = { val t = peek(); CJMark(path, t.line, t.column) }
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
    private def etype(self, type: Int): CJError = ekind(CJToken.typeRepr(type))
    private def ekind(self, kind: String): CJError = CJError(
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
        val list = List[T]()
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
    private def lit2char(rawText: String, mark: CJMark): Char {
        switch rawText {
            case "'\\''" = '\''
            case "'\\\"'" = '"'
            case "'\\\\'" = '\\'
            case "'\\n'" = '\n'
            case "'\\t'" = '\t'
            case "'\\r'" = '\r'
            case "'\\f'" = '\f'
            case "'\\0'" = '\0'
            else = {
                val chars = rawText.iter().toList()
                if chars.size() == 3 and chars[0] == '\'' and chars[2] == '\'' {
                    chars[1]
                } else {
                    throw CJError("Could not convert character literal: " + rawText, [mark])
                }
            }
        }
    }
    private def lit2str(rawText: String, mark: CJMark): String {
        if rawText.startsWith("r\"\"\"") {
            Assert.that(rawText.size() >= 7 and rawText.endsWith("\"\"\""))
            rawText[4:rawText.size() - 3]
        } else if rawText.startsWith("r\"") {
            Assert.that(rawText.size() >= 3 and rawText.endsWith("\""))
            rawText[1:rawText.size() - 1]
        } else if rawText.startsWith("\"\"\"") {
            Assert.that(rawText.size() >= 6 and rawText.endsWith("\"\"\""))
            litchars2str(rawText[3:rawText.size() - 3].iter(), mark)
        } else {
            Assert.that(
                rawText.size() >= 2 and rawText.startsWith("\"") and rawText.endsWith("\""))
            litchars2str(rawText[1:rawText.size() - 1].iter(), mark)
        }
    }
    private def litchars2str(chars: Iterator[Char], mark: CJMark): String {
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
                        throw CJError("Unrecognized escape " + ch.repr(), [mark])
                    }
                })
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
        val imports = List[CJAst.Import]()
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
        val members = List[CJAst.Member]()
        while not consume('}') {
            members.add(parseMember())
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
    private def parseMember(self): CJAst.Member {
        val comment = parseComment()
        val annotations = parseAnnotations()
        val modifiers = parseModifiers()
        switch peek().type {
            case CJToken.kwVAL
            case CJToken.kwVAR = CJAst.Member.field(parseField(comment, annotations, modifiers))
            case CJToken.kwCASE = CJAst.Member.case_(parseCase(comment, annotations, modifiers))
            case CJToken.kwIF
            case CJToken.kwDEF = CJAst.Member.method(parseMethod(comment, annotations, modifiers))
            case CJToken.kwCLASS
            case CJToken.kwTRAIT
            case CJToken.kwUNION = CJAst.Member.item(parseItem(comment, annotations, modifiers))
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
        val conditions = List[CJAst.TypeCondition]()
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
    private def parseParameters(self): List[CJAst.Local] = (
        parseJoin('(', ')', ',', () -> parseParameter()))
    private def parseParameter(self): CJAst.Local {
        val mutable = consume(CJToken.kwVAR)
        val mark = mark
        val name = parseId()
        val type = if not at(':') and name == "self" {
            CJAst.Type(mark, "Self", [])
        } else {
            expect(':')
            parseType()
        }
        CJAst.Local(mark, mutable, name, null(type))
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
    private def parseAnnotation(self): CJAst.Annotation {
        val mark = mark
        val name = switch peek().type {
            case CJToken.tINT
            case CJToken.tDOUBLE
            case CJToken.tTYPEID = next().text
            else = parseId()
        }
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
            CJAst.Type(mark, "Nullable", [type])
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
    private def parseExpr(self): Expr = parseExpr0(normalExpressionPrecedence)
    private def parseExpr0(self, precedence: Int): Expr {
        parseAtom()
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
                val innerType = if consume('[') { null(parseType()) } else { null }
                val inner = if consume('(') { null(parseExpr()) } else { null }
                Expr(mark, ED.null_(innerType, inner))
            }
            case CJToken.kwTRUE { next(); Expr(mark, ED.bool(true)) }
            case CJToken.kwFALSE { next(); Expr(mark, ED.bool(false)) }
            case CJToken.tCHAR = Expr(mark, ED.char(lit2char(next().text, mark)))
            case CJToken.tINT = Expr(mark, ED.int(Int(next().text)))
            case CJToken.tDOUBLE = Expr(mark, ED.double(Double(next().text)))
            case CJToken.tSTRING = Expr(mark, ED.string(lit2str(next().text, mark)))
            case CJToken.tBIGINT = Expr(mark, ED.bigint(BigInt(next().text)))
        }
    }
    private def atLambda(self): Bool {
        if at(CJToken.kwASYNC) {
            return true
        }
        if at(CJToken.tID) and atOffset(CJToken.tRIGHT_ARROW, 1) {
            return true
        }
        val start = i
        if not consume('(') {
            return false
        }
        while consume(',') or consume(CJToken.kwVAR) or consume(CJToken.tID) {}
        val ret = consume(')') and consume(CJToken.tRIGHT_ARROW)
        i = start
        ret
    }
    private def parseLambda(self): Expr {
        val mark = mark
        val isAsync = consume(CJToken.kwASYNC)
        val parameters = if at(CJToken.tID) {
            val pname = parseId()
            [CJAst.Local(mark, false, pname, null)]
        } else {
            parseJoin('(', ')', ',', () -> {
                val mutable = consume(CJToken.kwVAR)
                val pmark = self.mark
                val pname = parseId()
                CJAst.Local(pmark, mutable, pname, null)
            })
        }
        expect(CJToken.tRIGHT_ARROW)
        val body = parseExpr()
        Expr(mark, ED.lambda(isAsync, parameters, body))
    }
    private def parseBlock(self): Expr {
        val mark = mark
        expect('{')
        skipDelimiters()
        val exprs = List[Expr]()
        while not consume('}') {
            exprs.add(parseExpr0(0))
            expectDelimiters()
        }
        Expr(mark, ED.block(exprs))
    }
}
