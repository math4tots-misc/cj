package cjx.notc

import cjx.parser.Mark
import cjx.re.Regex
import cjx.notc.NCError
import cjx.re.Lexer
import cjx.notc.NCToken

class NCLexer {
    private static val lexer : Lexer[NCToken] = build()

    private def build(): Lexer[NCToken] {
        val b = Lexer[NCToken].builder()
        b.add("0x[0-9A-Fa-f]+", m -> tok(m, NCToken.tINT, s -> s.parseInt().get())) # hex literals
        b.add("\\d+", m -> tok(m, NCToken.tINT, s -> s.parseInt().get()))

        for type in NCToken.keywordTypes {
            b.add(NCToken.keywordString(type), m -> symtok(m, type))
        }

        b.add("[a-z_][a-zA-Z_0-9]*!", m -> tok(m, NCToken.tMACROID, s -> s))
        b.add("[a-z_][a-zA-Z_0-9]*", m -> tok(m, NCToken.tID, s -> s))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        b.add("==", m -> symtok(m, NCToken.tEQ))
        b.add("!=", m -> symtok(m, NCToken.tNE))
        b.add("<=", m -> symtok(m, NCToken.tLE))
        b.add(">=", m -> symtok(m, NCToken.tGE))

        # newline
        b.add("\n\\s*", m -> chartok(m))

        # comments
        b.add("//[^\n]*(\n\\s*//[^\n]*)*", m -> [])

        # whitespace
        b.add("[^\\S\n]+", m -> [])

        b.onEOF(m -> [NCToken(NCToken.tEOF, (), m.line, m.column)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw NCError("Unrecognized token", [mark])
        })

        b.build()
    }

    private def tok(
            m: Regex.MatchResult,
            type: Int,
            valf: Fn[String, NCToken.Value]): List[NCToken] = [
                NCToken(type, valf.call(m.matchText), m.line, m.column)]

    private def chartok(m: Regex.MatchResult): List[NCToken] {
        val type = m.originalString.charAt(m.start)
        [NCToken(type, (), m.line, m.column)]
    }

    private def symtok(m: Regex.MatchResult, type: Int): List[NCToken] = [
        NCToken(type, (), m.line, m.column)]

    def lex(filename: String, string: String): List[NCToken] = {
        val oldTokens = lexer.lex(filename, string)
        val newTokens = List[NCToken].empty()
        val stack = List[Int].empty()
        for token in oldTokens {
            switch token.type {
                case '('
                case '['
                case '{' = {
                    stack.add(token.type)
                    newTokens.add(token)
                }
                case ')'
                case '}'
                case ']' = {
                    if stack {
                        stack.pop()
                    }
                    newTokens.add(token)
                }
                case '\n' = if not stack or stack.last() == '{' {
                    newTokens.add(token)
                }
                else = newTokens.add(token)
            }
        }
        newTokens
    }
}
