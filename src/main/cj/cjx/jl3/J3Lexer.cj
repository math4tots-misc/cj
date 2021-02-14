package cjx.jl3

import cjx.jl3.J3Error
import cjx.jl3.J3Mark
import cjx.re.Regex
import cjx.re.Lexer
import cjx.jl3.J3Token

class J3Lexer {

    def lex(filename: String, string: String): List[J3Token] = {
        val inTokens = lexer.lex(filename, string)

        # omit newline tokens in between '()' and '[]' grouping symbols
        # (while keeping them at the top level and between '{}' grouping symbols)
        val stack: List[Int] = []
        val outTokens: List[J3Token] = []
        for token in inTokens {
            switch token.type {
                case '('
                case '['
                case '{' = {
                    stack.add(token.type)
                    outTokens.add(token)
                }
                case ')'
                case ']'
                case '}' = if stack {
                    stack.pop()
                    outTokens.add(token)
                }
                case '\n' = if not stack or stack.last() == '{' {
                    outTokens.add(token)
                }
                else = outTokens.add(token)
            }
        }

        outTokens
    }

    private static val lexer: Lexer[J3Token] = build()

    private def build(): Lexer[J3Token] {
        val b = Lexer[J3Token].builder()

        b.add("(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?", m -> tok(J3Token.tDOUBLE, m))
        b.add("\\d+(e|E)-?\\d+", m -> tok(J3Token.tDOUBLE, m))
        b.add("0x[0-9A-Fa-f]+", m -> tok(J3Token.tINT, m)) # hex literals
        b.add("\\d+", m -> tok(J3Token.tINT, m))
        for type in J3Token.keywordTypes {
            b.add(J3Token.keywordString(type), m -> symtok(type, m))
        }
        b.add("[A-Z](\\w|\\$)*", m -> tok(J3Token.tTYPEID, m))
        b.add("[a-z_](\\w|\\$)*", m -> tok(J3Token.tID, m))
        b.add("'\\\\.'", m -> tok(J3Token.tCHAR, m))
        b.add("'[^'\\\\]'", m -> tok(J3Token.tCHAR, m))
        b.add("\"(\\\\.|[^\"\\\\])*\"", m -> tok(J3Token.tSTRING, m))

        # single character symbol tokens
        b.add(
            "\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?",
            m -> chartok(m))

        # multi-character symbol tokens
        b.add("==", m -> symtok(J3Token.tEQ, m));
        b.add("!=", m -> symtok(J3Token.tNE, m));
        b.add("<=", m -> symtok(J3Token.tLE, m));
        b.add(">=", m -> symtok(J3Token.tGE, m));
        b.add("<<", m -> symtok(J3Token.tLSHIFT, m));
        b.add(">>", m -> symtok(J3Token.tRSHIFT, m));
        b.add(">>>", m -> symtok(J3Token.tRSHIFTU, m));
        b.add("//", m -> symtok(J3Token.tTRUNCDIV, m));
        b.add("->", m -> symtok(J3Token.tRIGHT_ARROW, m));
        b.add("\\*\\*", m -> symtok(J3Token.tPOWER, m));
        b.add("\\+\\+", m -> symtok(J3Token.tPLUSPLUS, m));
        b.add("--", m -> symtok(J3Token.tMINUSMINUS, m));
        b.add("\\+=", m -> symtok(J3Token.tPLUS_EQ, m));
        b.add("-=", m -> symtok(J3Token.tMINUS_EQ, m));
        b.add("\\*=", m -> symtok(J3Token.tSTAR_EQ, m));
        b.add("%=", m -> symtok(J3Token.tREM_EQ, m));

        # newline
        b.add("\n\\s*", m -> chartok(m))

        # comments
        b.add("##[^\n]*(\n\\s*##[^\n]*)*", m -> tok(J3Token.tCOMMENT, m))
        b.add("#[^\n]*(\n\\s*#[^\n]*)*", m -> [])

        # whitespace
        b.add("[^\\S\n]+", m -> [])

        b.onEOF(m -> [J3Token(J3Token.tEOF, "", m.line, m.column)])
        b.onError(m ->
            throw J3Error("Unrecognized token", [J3Mark(m.filename, m.line, m.column)]))
        b.build()
    }

    private def tok(type: Int, m: Regex.MatchResult): List[J3Token] = [
        J3Token(type, m.matchText, m.line, m.column)]

    private def chartok(m: Regex.MatchResult): List[J3Token] = {
        val type = m.originalString.charAt(m.start)
        [J3Token(type, "", m.line, m.column)]
    }

    private def symtok(type: Int, m: Regex.MatchResult): List[J3Token] = [
        J3Token(type, "", m.line, m.column)]
}
