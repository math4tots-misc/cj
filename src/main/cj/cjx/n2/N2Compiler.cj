package cjx.n2

import cj.Error
import cj.StringBuilder
import cj.Int32Array
import www.JSObject
import cjx.n2.N2Token
import cjx.n2.N2Lexer
import cjx.n2.N2Preprocessor
import cj.FS
import cj.Argv
import cjx.n2.N2IR
import cjx.n2.N2Codegen
import www.wa.WebAssembly
import cjx.n2.N2Parser

class N2Compiler {
    private val preprocessor: N2Preprocessor = N2Preprocessor("src/main/n2")
    var includePrelude = true

    def lex(self, filepath: String, contents: String): List[N2Token] {
        val rawTokens: List[N2Token] = []
        if includePrelude {
            rawTokens.addAll(N2Lexer.lex("<prelude>", include_str!("prelude.n2")))
            Assert.equal(rawTokens.last().type, N2Token.tEOF)
            rawTokens.pop()
        }
        rawTokens.addAll(N2Lexer.lex(filepath, FS.readFile(filepath)))
        preprocessor.process(rawTokens)
    }

    def parse(self, filepath: String, contents: String): N2IR.Program {
        val tokens = lex(filepath, contents)
        N2Parser.parseAll(tokens)
    }

    def translate(self, filepath: String, contents: String): String {
        val program = parse(filepath, contents)
        N2Codegen.emit(program, "main")
    }

    def main() {
        val self = Self()
        var mode = ""
        var outFile = ""
        var filepath = ""
        for arg in Argv() {
            switch mode {
                case "-j" { outFile = arg; mode = "" }
                case "" = switch arg {
                    case "-j" { mode = "-j" }
                    else { filepath = arg }
                }
            }
        }
        switch mode {
            case "" = ()
            case "-j" { throw Error("-j expects an output js file path") }
        }
        if not filepath {
            throw Error("input filepath must be specified")
        }
        val js = translate(filepath, FS.readFile(filepath))
        if outFile {
            if outFile == "-" {
                IO.println(js)
            } else {
                FS.writeFile(outFile, js)
            }
        } else {
            js!(Unit, "eval(", js, ")")
        }
    }
}
