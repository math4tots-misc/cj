package cjx.lang.main

import cj.FS
import cj.Argv
import cjx.lang.CJLexer

## Sample main class that will simply lex and print each token in the given file
class Lexer {
    def main() {
        val (filename, data) = if Argv() {
            val filename = Argv()[0]
            val data = FS.readFile(filename)
            (filename, data)
        } else {
            ("<stdin>", IO.input())
        }
        IO.println("Lexing " + filename)
        val tokens = CJLexer.lex(filename, data)
        for token in tokens {
            IO.println(token)
        }
    }
}
