package cjx.cc

import cjx.cc.C2RT
import cjx.cc.C2MemDesc
import www.wa.WebAssembly
import cj.Uint8Array
import cjx.cc.C2Codegen
import cj.Error
import cj.Argv
import cjx.cc.C2Preprocessor
import cj.FS
import cjx.cc.C2IR
import cjx.cc.C2Token
import cjx.cc.C2Lexer
import cjx.cc.C2Parser

class C2Compiler {
    val preprocessor: C2Preprocessor = C2Preprocessor()
    var includePrelude = true

    def lex(self, filepath: String, contents: String): List[C2Token] {
        val rawTokens: List[C2Token] = []
        if includePrelude {
            rawTokens.addAll(C2Lexer.lex("<prelude>", include_str!("__prelude.c")))
            Assert.equal(rawTokens.last().type, C2Token.tEOF)
            rawTokens.pop()
        }
        rawTokens.addAll(C2Lexer.lex(filepath, contents))
        preprocessor.process(rawTokens)
    }

    def parse(self, filepath: String, contents: String): C2IR.TranslationUnit {
        val tokens = lex(filepath, contents)
        C2Parser.parse(tokens)
    }

    def translate(self, filepath: String, contents: String): Tuple[Uint8Array, C2MemDesc] {
        val tu = parse(filepath, contents)
        val codegen = C2Codegen()
        codegen.emit(tu)
    }

    def run(self, filepath: String, contents: String): Int {
        val rt = C2RT()
        val (binary, memDesc) = translate(filepath, contents)
        val importObject = rt.newImportObject(memDesc)
        val module = WebAssembly.Module(binary)
        val instance = WebAssembly.Instance(module, importObject)
        instance.exports.call("main").unsafeCast()
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
        val exitCode = run(filepath, FS.readFile(filepath))
        IO.println("exitCode = " + exitCode)
    }
}
