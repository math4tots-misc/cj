package cjx.n2

import cjx.parser.Mark
import cjx.re.Regex
import cjx.n2.N2Error
import cjx.re.Lexer
import cjx.n2.N2Token

class N2Lexer {
    private static val lexer : Lexer[N2Token] = build()

    private def build(): Lexer[N2Token] {
        val b = Lexer[N2Token].builder()
        b.add("0x[0-9A-Fa-f]+", m -> tok(m, N2Token.tINT, s -> s.parseInt().get())) # hex literals
        b.add("\\d+", m -> tok(m, N2Token.tINT, s -> s.parseInt().get()))

        b.add("'[^'\\\\]'", m -> tok(m, N2Token.tINT, s -> s[1].toInt()))
        b.add("'\\\\'", m -> tok(m, N2Token.tINT, s -> '\\'.toInt()))

        # TODO: properly handle string literals
        b.add("\"(\\\\.|[^\"\\\\])*\"", m -> tok(m, N2Token.tSTRING, s -> s.unrepr()))

        for type in N2Token.keywordTypes {
            b.add(N2Token.keywordString(type), m -> symtok(m, type))
        }

        b.add("[a-z_][a-zA-Z_0-9]*!", m -> tok(m, N2Token.tMACROID, s -> s))
        b.add("[a-z_][a-zA-Z_0-9]*", m -> tok(m, N2Token.tID, s -> s))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        b.add("==", m -> symtok(m, N2Token.tEQ))
        b.add("!=", m -> symtok(m, N2Token.tNE))
        b.add("<=", m -> symtok(m, N2Token.tLE))
        b.add(">=", m -> symtok(m, N2Token.tGE))

        # newline
        b.add("\n\\s*", m -> chartok(m))

        # comments
        b.add("//[^\n]*(\n\\s*//[^\n]*)*", m -> [])

        # whitespace
        b.add("[^\\S\n]+", m -> [])

        b.onEOF(m -> [N2Token(N2Token.tEOF, (), m.line, m.column)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw N2Error("Unrecognized token", [mark])
        })

        b.build()
    }

    private def tok(
            m: Regex.MatchResult,
            type: Int,
            valf: Fn[String, N2Token.Value]): List[N2Token] = {
        [N2Token(type, valf.call(m.matchText), m.line, m.column)]
    }

    private def chartok(m: Regex.MatchResult): List[N2Token] {
        val type = m.originalString.charAt(m.start)
        [N2Token(type, (), m.line, m.column)]
    }

    private def symtok(m: Regex.MatchResult, type: Int): List[N2Token] = [
        N2Token(type, (), m.line, m.column)]

    def lex(filename: String, string: String): List[N2Token] = {
        val oldTokens = lexer.lex(filename, string)
        val newTokens = List[N2Token].empty()
        val stack = List[Int].empty()
        for token in oldTokens {
            token.filepath = filename
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
