package cjx.jl1

import cjx.jl1.JLLexer
import cj.Error
import cjx.jl1.JLType
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
            classes.add(parseClass())
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

    def parseClass(self): JLAstClass {
        val mark = mark
        val comment = parseComment()
        skipDelimiters()
        val modifiers = parseModifiers()
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
            parseMember()
            skipDelimiters()
        }
        expectDelimiters()
        JLAstClass(mark, comment, modifiers, isInterface, shortName, interfaces, members)
    }

    def parseType(self): JLAstType {
        # TODO: type args
        val mark = mark
        val name = parseTypeId()
        JLAstType(mark, name, [])
    }

    def parseMember(self): JLAstClass.Member {
        throw Error("TODO")
    }
}
