package cjx.jl1.main

import cjx.jl1.JLLexer
import cj.FS
import cj.Argv

class Lexer {
    def main() {
        for filename in Argv() {
            val data = FS.readFile(filename)
            IO.println("LEXING " + filename)
            val tokens = JLLexer.lex(filename, data)
            for token in tokens {
                IO.println("  " + token.repr())
            }
        }
    }
}
