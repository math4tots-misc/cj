package cjx.cc

import cj.StringBuilder
import cjx.cc.C2Token
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

        b.add("'[^'\\\\]'", m -> tok(m, C2Token.tCHAR, s -> s[1].toInt()))
        b.add("'\\\\.'", m -> tok(m, C2Token.tCHAR,
            s -> readEscapeChar(m, s.toList(), 2).f0.toInt()))

        b.add("\"([^'\\\\]|\\\\.)*\"", m -> tok(m, C2Token.tSTR, s -> {
            var escape = false
            val sb = StringBuilder()
            val chars = s[1:-1].toList()
            for i = 0; i < chars.size(); i++ {
                if chars[i] == '\\' {
                    i++
                    val (ch, newI) = readEscapeChar(m, chars, i)
                    Assert(newI > i)
                    sb.char(ch)
                    i = newI - 1 # account for automatic i++
                } else {
                    sb.char(chars[i])
                }
                IO.println("  " + sb.toString().repr())
            }
            val out = sb.toString()
            IO.println("" + s.repr() + " -> " + out.repr())
            out
        }))

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

    private def readEscapeChar(m: Regex.MatchResult, chars: List[Char], var i: Int): Tuple[Char, Int] {
        val escChar = chars[i]
        val (c, newI) = switch escChar {
            case '0' = ('\0', i + 1)
            case '\'' = ('\'', i + 1)

            # these overlap with JSON
            case '"' = ('"', i + 1)
            case 'b' = ('\b', i + 1)
            case 'f' = ('\f', i + 1)
            case 'r' = ('\r', i + 1)
            case 't' = ('\t', i + 1)
            case 'n' = ('\n', i + 1)

            # additional escapes required by the C standard
            case 'a' = ((0x07).toChar(), i + 1)
            case 'v' = ((0x0B).toChar(), i + 1)

            # GNU C extension
            case 'e' = ((0x1B).toChar(), i + 1)

            else {
                if escChar >= '0' and escChar <= '7' {
                    # octal
                    var ch = Int(escChar.toString())
                    i++
                    if i < chars.size() and chars[i] >= '0' and chars[i] <= '7' {
                        ch = 8 * ch + Int(chars[i].toString())
                        i++
                        if i < chars.size() and chars[i] >= '0' and chars[i] <= '7' {
                            ch = 8 * ch + Int(chars[i].toString())
                            i++
                        }
                    }
                    (ch.toChar(), i)
                } else if escChar == 'x' {
                    i++
                    if i >= chars.size() or not isHexDigit(chars[i]) {
                        val mark = Mark(m.filename, m.line, m.column)
                        val ec = if i >= chars.size() { "EOS" } else { chars[i].repr() }
                        throw MError("Invalid hex escape " + ec, [mark])
                    }
                    var ch = Int.fromHex(chars[i].toString())
                    i++
                    while i < chars.size() and isHexDigit(chars[i]) {
                        ch = 16 * ch + Int.fromHex(chars[i].toString())
                        i++
                    }
                    IO.println("" + chars + " -> " + ch + " -> " + ch.toChar())
                    (ch.toChar(), i)
                } else {
                    (escChar, i + 1)
                }
            }
            # else = throw MError(
            #     "Unrecognized escape " + s, [Mark(m.filename, m.line, m.column)])
        }
        (c, newI)
    }

    private def isHexDigit(ch: Char): Bool = (
        (ch >= '0' and ch <= '9') or (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'))

    def lex(filepath: String, string: String): List[C2Token] = lexer.lex(filepath, string)
}
