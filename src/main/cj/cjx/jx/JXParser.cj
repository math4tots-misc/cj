package cjx.jx

import cjx.jx.JXExpr
import compiler.CJMark
import compiler.CJError
import cjx.jx.JXScope
import compiler.CJToken

class JXParser {
    val path: String
    val tokens: List[CJToken]
    var i = 0

    def __get_mark(self): CJMark = { val t = peek(); CJMark(path, t.line, t.column) }
    def peek(self): CJToken = tokens[i]
    def at(self, type: Int): Bool = tokens[i].type == type
    def next(self): CJToken { i = i + 1; tokens[i - 1] }
    def consume(self, type: Int): Bool { if at(type) { next(); true } else { false } }
    def expect(self, type: Int): CJToken { if at(type) { next() } else { throw etype(type) } }
    def etype(self, type: Int): CJError = ekind(CJToken.typeRepr(type))
    def ekind(self, kind: String): CJError = CJError(
        "Expected " + kind + " but got " + CJToken.typeRepr(peek().type), [mark])

    def parseFile(self, scope: JXScope) {

    }

    def parseExpr(self, scope: JXScope): JXExpr = parseAtom(scope)

    def parseAtom(self, scope: JXScope): JXExpr {
        val mark = mark
        switch peek().type {
            case CJToken.tINT {
                val text = next().text
                JXExpr(
                    mark,
                    () -> (),
                    () -> {
                        val out = scope.getCodeGen(mark, "@out")
                        out.write(text)
                    })
            }
            case CJToken.tSTRING {
                val text = next().text
                JXExpr(
                    mark,
                    () -> (),
                    () -> {
                        val out = scope.getCodeGen(mark, "@out")
                        out.write(text)
                    }
                )
            }
            else = throw ekind("expression")
        }
    }
}
