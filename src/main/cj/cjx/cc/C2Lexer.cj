package cjx.cc

import cj.DynamicBuffer
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
        b.add("0(x|X)[0-9A-Fa-f]+", m -> itok(m)) # hex literals
        b.add("0\\d+", m -> hitok(m))
        b.add("0(b|B)\\d+", m -> bitok(m))
        b.add("\\d+", m -> itok(m))
        b.add("0(x|X)[0-9A-Fa-f]+(l|L)", m ->
            tok(m, C2Token.tLONG, s -> BigInt(s[:-1]))) # hex literals
        b.add("\\d+(l|L)", m -> tok(m, C2Token.tLONG, s -> BigInt(s[:-1])))

        for type in C2Token.keywordTypes {
            b.add(C2Token.keywordString(type), m -> symtok(m, type))
        }
        b.add("_Bool", m -> tok(m, C2Token.kwBOOL, s -> ()))

        b.add("[a-zA-Z_][a-zA-Z_0-9]*", m -> tok(m, C2Token.tIDENT, s -> s))

        b.add("'[^'\\\\]'", m -> tok(m, C2Token.tCHAR, s -> s[1].toInt()))
        b.add("'\\\\.'", m -> tok(m, C2Token.tCHAR, s -> readEscapeChar(m, s, 2).f0))
        b.add("'\\\\x?[0-9A-F]+'", m -> tok(m, C2Token.tCHAR, s -> readEscapeChar(m, s, 2).f0))

        b.add("\"([^'\"\\\\]|\\\\.)*\"", m -> tok(m, C2Token.tSTR, s -> {
            var escape = false
            val dbuf = DynamicBuffer(0)
            val sb = StringBuilder()
            for i = 1; i + 1 < s.len(); {
                if s[i] == '\\' {
                    i++
                    val (ch, newI) = readEscapeChar(m, s, i)
                    Assert(newI > i)
                    dbuf.addUint8(ch)
                    i = newI
                } else {
                    dbuf.addUTF8(s[i].toString())
                    i += s[i].size()
                }
            }
            dbuf.asUint8Array()
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
        b.add("->", m -> symtok(m, C2Token.tARROW))
        b.add("\\+=", m -> symtok(m, C2Token.tPLUS_EQ))
        b.add("-=", m -> symtok(m, C2Token.tMINUS_EQ))
        b.add("\\*=", m -> symtok(m, C2Token.tSTAR_EQ))
        b.add("/=", m -> symtok(m, C2Token.tDIV_EQ))

        # whitespace
        b.add("\\s+", m -> [])

        # comments
        b.add("//[^\n]*(\n\\s*//[^\n]*)*", m -> [])
        b.add("/\\*([^*]|\\*[^/])*\\*/", m -> [])

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

    private def itok(m: Regex.MatchResult): List[C2Token] = {
        val text = m.matchText
        if text.len() >= 10 and BigInt(text) > BigInt(Int.max) {
            throw MError(
                "Int literal will overflow: " + text,
                [Mark(m.filename, m.line, m.column)])
        } else {
            [C2Token(C2Token.tINT, Int(text), m.line, m.column, m.filename)]
        }
    }

    private def hitok(m: Regex.MatchResult): List[C2Token] = {
        val text = m.matchText
        [C2Token(C2Token.tINT, Int(Int.fromOctal(text)), m.line, m.column, m.filename)]
    }

    private def bitok(m: Regex.MatchResult): List[C2Token] = {
        val text = m.matchText
        [C2Token(C2Token.tINT, Int(Int.fromBinary(text[2:])), m.line, m.column, m.filename)]
    }

    private def chartok(m: Regex.MatchResult): List[C2Token] {
        val type = m.originalString.charAt(m.start)
        [C2Token(type, (), m.line, m.column, m.filename)]
    }

    private def symtok(m: Regex.MatchResult, type: Int): List[C2Token] = [
        C2Token(type, (), m.line, m.column, m.filename)]

    private def readEscapeChar(m: Regex.MatchResult, s: String, var i: Int): Tuple[Int, Int] {
        val escChar = s[i]
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
                    if i < s.len() and s[i] >= '0' and s[i] <= '7' {
                        ch = 8 * ch + Int(s[i].toString())
                        i++
                        if i < s.len() and s[i] >= '0' and s[i] <= '7' {
                            ch = 8 * ch + Int(s[i].toString())
                            i++
                        }
                    }
                    (ch.toChar(), i)
                } else if escChar == 'x' {
                    i++
                    if i >= s.len() or not isHexDigit(s[i]) {
                        val mark = Mark(m.filename, m.line, m.column)
                        val ec = if i >= s.len() { "EOS" } else { s[i].repr() }
                        throw MError("Invalid hex escape " + ec, [mark])
                    }
                    var ch = Int.fromHex(s[i].toString())
                    i++
                    while i < s.len() and isHexDigit(s[i]) {
                        ch = 16 * ch + Int.fromHex(s[i].toString())
                        i++
                    }
                    (ch.toChar(), i)
                } else {
                    (escChar, i + 1)
                }
            }
            # else = throw MError(
            #     "Unrecognized escape " + s, [Mark(m.filename, m.line, m.column)])
        }
        (c.toInt(), newI)
    }

    private def isHexDigit(ch: Char): Bool = (
        (ch >= '0' and ch <= '9') or (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'))

    def lex(filepath: String, string: String): List[C2Token] = lexer.lex(filepath, string)
}
