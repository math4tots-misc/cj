package uu

import uu.UULexer
import uu.UUAst
import cj.StringBuilder
import uu.UUAst.File
import uu.UUAst.Item
import uu.UUAst.Import
import uu.UUAst.Annotation
import uu.UUAst.Modifier
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

    def mark(self): Mark = markAt(peek())
    def markAt(self, token: UUToken): Mark = Mark(token.filepath, token.line, token.column)
    def errorAt(self, message: String, token: UUToken): NoReturn = throw MError(
        message, [markAt(token)])
    def errorAtMark(self, message: String, mark: Mark): NoReturn = throw MError(
        message, [mark])
    private def expectDelimiters(self) {
        if not at(';') and not at('}') and not at('\n') {
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
    private def parseItem(
            self,
            comment: String?,
            annotations: List[Annotation],
            modifiers: List[Modifier]): Item {
        val kind = parseItemKind()
        val comment = parseComment()
        val annotations = parseAnnotations()
        error("TODO")
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
}
