package uu

import uu.UULexer
import uu.UUAst
import cj.StringBuilder
import uu.UUAst.File
import uu.UUAst.Item
import uu.UUAst.Import
import uu.UUAst.Annotation
import uu.UUAst.Modifier
import uu.UUAst.Member
import uu.UUAst.Method
import uu.UUAst.Var
import uu.UUAst.TraitExpr
import uu.UUAst.TypeExpr
import uu.UUAst.Expr
import cjx.parser.MError
import cjx.parser.Mark
import uu.UUToken
import cjx.parser.ParserMixin

class UUParser: ParserMixin[UUToken] {

    def parse(filepath: String, contents: String): File {
        val tokens = UULexer.lex(filepath, contents)
        val parser = Self(tokens)
        parser.parseFile()
    }

    def typeOfToken(token: UUToken): Int = token.type
    def nameOfType(type: Int): String = UUToken.typeRepr(type)

    private val tokens: List[UUToken]
    private var i = 0
    private var outerName = ""

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: UUToken): Mark = Mark(token.filepath, token.line, token.column)
    def errorAt(self, message: String, token: UUToken): NoReturn = throw MError(
        message, [markAt(token)])
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw MError(
        message, [mark])
    private def expectDelimiters(self) {
        if not at(';') and not at('}') and not at('\n') and not at(UUToken.tEOF) {
            throw errorKind("delimiter")
        }
        skipDelimiters()
    }
    private def skipDelimiters(self) {
        while at(';') or at('\n') {
            next()
        }
    }
    private def parseId(self): String = expect(UUToken.tID).stringValue
    private def parseTypeId(self): String = expect(UUToken.tTYPEID).stringValue
    private def parseTypeIdEx(self): String {
        val sb = StringBuilder()
        sb.add(parseTypeId())
        while at('.') and atOffset(UUToken.tTYPEID, 1) {
            expect('.')
            sb.add(".")
            sb.add(parseTypeId())
        }
        sb.toString()
    }

    private def parseFile(self): File {
        val mark = mark()
        expect(UUToken.kwPACKAGE)
        val packageName = parsePackageName()
        outerName = packageName
        expectDelimiters()
        val imports: List[Import] = []
        while at(UUToken.kwIMPORT) {
            imports.add(parseImport())
        }
        val comment = parseComment()
        val annotations = parseAnnotations()
        val modifiers = parseModifiers()
        val item = parseItem(comment, annotations, modifiers)
        File(mark, packageName, imports, item)
    }

    ## ==========================================================================================
    ## Item and members
    ## ==========================================================================================
    private def parseItem(
            self,
            comment: String?,
            annotations: List[Annotation],
            modifiers: List[Modifier]): Item {
        val kind = parseItemKind()
        val mark = mark()
        val shortName = parseTypeId()
        val name = outerName + "." + shortName
        val members: List[Member] = []

        val savedOuterName = outerName
        outerName = name
        expect('{')
        skipDelimiters()
        while not consume('}') {
            parseMember(members)
        }
        expectDelimiters()
        outerName = savedOuterName

        Item(mark, comment, annotations, modifiers, kind, shortName, name, members)
    }
    private def parseMember(self, members: List[Member]) {
        val comment = parseComment()
        val annotations = parseAnnotations()
        val modifiers = parseModifiers()
        switch peek().type {
            case UUToken.kwTRAIT
            case UUToken.kwCLASS
            case UUToken.kwUNION = members.add(parseItem(comment, annotations, modifiers))
            case UUToken.kwIF
            case UUToken.kwDEF = members.add(parseMethod(comment, annotations, modifiers))
            else = throw errorKind("item member")
        }
    }
    private def parseItemKind(self): Item.Kind {
        switch peek().type {
            case UUToken.kwCLASS { next(); Item.Kind.class_ }
            case UUToken.kwUNION { next(); Item.Kind.union_ }
            case UUToken.kwTRAIT { next(); Item.Kind.trait_ }
            case UUToken.kwINTERFACE { next(); Item.Kind.interface_ }
            else = throw errorKind("class, union, trait or interface")
        }
    }
    private def parseMethod(
            self,
            comment: String?,
            annotations: List[Annotation],
            modifiers: List[Modifier]): Method {
        val mark = mark()
        expect(UUToken.kwDEF)
        val name = if at(UUToken.tID) { parseId() } else { "__new" }
        val parameters = parseParameters()
        val returnType = if consume(':') { parseType() } else { TypeExpr(mark, "Void", []) }
        val body = if consume('=') {
            null(parseExpr())
        } else if at('{') {
            null(parseBlock())
        } else { null }
        expectDelimiters()
        Method(mark, comment, annotations, modifiers, name, parameters, returnType, body)
    }
    private def parseParameters(self): List[Var] = parseJoin('(', ')', ',', () -> parseParameter())
    private def parseParameter(self): Var {
        val mutable = consume(UUToken.kwVAR)
        val mark = mark()
        val name = parseId()
        val type = if at(':') or name != "self" {
            expect(':')
            parseType()
        } else { TypeExpr(mark, "Self", []) }
        Var(mark, mutable, name, type)
    }

    ## ==========================================================================================
    ## Type and Trait expressions
    ## ==========================================================================================
    private def parseType(self): TypeExpr {
        val mark = mark()
        val name = parseTypeIdEx()
        val args = parseTypeArgs()
        var texpr = TypeExpr(mark, name, args)
        if at('?') {
            val qmark = mark()
            next()
            texpr = TypeExpr(mark, "Nullable", [texpr])
        }
        texpr
    }
    private def parseTrait(self): TraitExpr {
        val mark = mark()
        val name = parseTypeIdEx()
        val args = parseTypeArgs()
        TraitExpr(mark, name, args)
    }
    private def parseTypeArgs(self): List[TypeExpr] = parseJoinOpt(
        '[', ']', ',', () -> parseType())

    ## ==========================================================================================
    ## Package, imports, comments and modifiers
    ## ==========================================================================================
    private def parsePackageName(self): String {
        val sb = StringBuilder()
        sb.add(parseId())
        while at('.') and atOffset(UUToken.tID, 1) {
            expect('.')
            sb.add(".")
            sb.add(parseId())
        }
        sb.toString()
    }
    private def parseImport(self): Import {
        expect(UUToken.kwIMPORT)
        val mark = mark()
        val (name, alias) = parseFullItemNameAndAlias()
        expectDelimiters()
        Import(mark, name, alias)
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
        val alias = if consume(UUToken.kwAS) { parseTypeId() } else { shortName }
        (name, alias)
    }
    private def parseComment(self): String? {
        if at(UUToken.tCOMMENT) {
            val ret = null(expect(UUToken.tCOMMENT).stringValue)
            expectDelimiters()
            ret
        } else { null }
    }
    private def parseModifiers(self): List[Modifier] {
        val modifiers: List[Modifier] = []
        var repeat = true
        while repeat {
            switch peek().type {
                case UUToken.kwNATIVE { next(); modifiers.add(Modifier.native_) }
                case UUToken.kwSTATIC { next(); modifiers.add(Modifier.static_) }
                case UUToken.kwPUBLIC { next(); modifiers.add(Modifier.public_) }
                case UUToken.kwPRIVATE { next(); modifiers.add(Modifier.private_) }
                case UUToken.kwASYNC { next(); modifiers.add(Modifier.async_) }
                else = { repeat = false }
            }
        }
        modifiers
    }

    ## ==========================================================================================
    ## Annotations
    ## ==========================================================================================
    private def parseAnnotations(self): List[UUAst.Annotation] {
        val list: List[UUAst.Annotation] = []
        while consume('@') {
            list.add(parseAnnotation())
            skipDelimiters()
        }
        list
    }
    private def parseAnnotationIdPart(self): String {
        switch peek().type {
            case UUToken.tINT = next().intValue.toString()
            case UUToken.tDOUBLE = next().doubleValue.toString()
            case UUToken.tTYPEID = next().stringValue
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
    private def parseAnnotation(self): UUAst.Annotation {
        val mark = mark()
        val name = parseAnnotationId()
        val args = parseJoin('(', ')', ',', () -> parseAnnotation())
        UUAst.Annotation(mark, name, args)
    }

    ## ==========================================================================================
    ## Expressions
    ## ==========================================================================================
    private def parseExpr(self): Expr = parseAtom()
    private def parseAtom(self): Expr {
        val mark = mark()
        switch peek().type {
            case UUToken.tINT = Expr.int(mark, next().intValue)
            case '{' = parseBlock()
            case '(' {
                next()
                val inner = parseExpr()
                expect(')')
                inner
            }
            else = errorKind("expression")
        }
    }
    private def parseBlock(self): Expr {
        val mark = mark()
        expect('{')
        val exprs: List[Expr] = []
        while not consume('}') {
            exprs.add(parseExpr())
            expectDelimiters()
        }
        Expr.block(mark, exprs)
    }
}
