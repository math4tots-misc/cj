package cjx.cc2

import cjx.cc2.C2Token
import cjx.parser.Mark
import cjx.parser.MError
import cjx.re.Lexer
import cjx.re.Regex

class C2Lexer {
    private static val lexer : Lexer[C2Token] = build()

    private def build(): Lexer[C2Token] {
        val b = Lexer[C2Token].builder()
        b.add("0x[0-9A-Fa-f]+", m -> tok(m, C2Token.tINT, s -> s.parseInt().get())) # hex literals
        b.add("\\d+", m -> tok(m, C2Token.tINT, s -> s.parseInt().get()))

        for type in C2Token.keywordTypes {
            b.add(C2Token.keywordString(type), m -> symtok(m, type))
        }

        b.add("[a-zA-Z_][a-zA-Z_0-9]*", m -> tok(m, C2Token.tIDENT, s -> s))

        b.add("'[^'\\\\]'", m -> tok(m, C2Token.tINT, s -> s[1].toInt()))
        b.add("'\\\\[nt0']'", m -> tok(m, C2Token.tINT, s -> switch s[2] {
                case 'n' = '\n'
                case 't' = '\t'
                case '0' = '\0'
                case '\'' = '\''
                else = throw MError(
                    "Unrecognized escape " + s, [Mark(m.filename, m.line, m.column)])
            }.toInt()
        ))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        b.add("==", m -> symtok(m, C2Token.tEQ))
        b.add("!=", m -> symtok(m, C2Token.tNE))
        b.add("<=", m -> symtok(m, C2Token.tLE))
        b.add(">=", m -> symtok(m, C2Token.tGE))
        b.add("\\+\\+", m -> symtok(m, C2Token.tINCR))
        b.add("--", m -> symtok(m, C2Token.tDECR))

        # whitespace
        b.add("\\s+", m -> [])

        # comments
        b.add("//[^\n]*(\n\\s*//[^\n]*)*", m -> [])

        b.onEOF(m -> [C2Token(C2Token.tEOF, (), m.line, m.column, m.filename)])

        b.onError(m -> {
            val mark = Mark(m.filename, m.line, m.column)
            throw MError("Unrecognized token", [mark])
        })

        b.build()
    }

    private def tok(
            m: Regex.MatchResult,
            type: Int,
            valf: Fn[String, C2Token.Value]): List[C2Token] = [
                C2Token(type, valf.call(m.matchText), m.line, m.column, m.filename)]

    private def chartok(m: Regex.MatchResult): List[C2Token] {
        val type = m.originalString.charAt(m.start)
        [C2Token(type, (), m.line, m.column, m.filename)]
    }

    private def symtok(m: Regex.MatchResult, type: Int): List[C2Token] = [
        C2Token(type, (), m.line, m.column, m.filename)]

    def lex(filepath: String, string: String): List[C2Token] = lexer.lex(filepath, string)
}
