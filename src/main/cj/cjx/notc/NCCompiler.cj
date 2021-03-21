package cjx.notc

import cj.Error
import cj.StringBuilder
import cj.Int32Array
import www.JSObject
import cjx.notc.NCToken
import cjx.notc.NCLexer
import cjx.notc.NCPreprocessor
import cj.FS
import cj.Argv
import cjx.notc.NCIR
import cjx.notc.NCCodegen
import www.wa.WebAssembly
import cjx.notc.NCParser
import cjx.binaryen.Binaryen
import cj.Uint8Array

class NCCompiler {
    var includePrelude = true

    def compileString(self, string: String): Uint8Array {
        val sources: List[List[NCToken]] = []
        # val program = NCIR.Program()
        if includePrelude {
            sources.add(NCLexer.lex("<prelude>", include_str!("prelude.notc")))
        }
        sources.add(NCLexer.lex("<string>", string))
        val program = NCParser.parseAll(sources)
        NCCodegen.emit(program)
    }

    def compileAndRunMain(self, string: String): Int {
        val binary = compileString(string)
        val module = WebAssembly.Module(binary)
        val instance = WebAssembly.Instance(module, jsobj!(js: jsobj!(
            memory: WebAssembly.Memory(1, 1024),
        )))
        instance.exports.call("main").unsafeCast()
    }

    def main() {
        val self = Self()
        val filepath = Argv()[0]
        val contents = FS.readFile(filepath)
        val preprocessor = NCPreprocessor("src/main/notc")
        val tokens = preprocessor.lex(filepath, contents)
        val program = NCParser.parseAll([
            NCLexer.lex("<prelude>", include_str!("prelude.notc")),
            tokens
        ])
        val binary = NCCodegen.emit(program)
        val module = WebAssembly.Module(binary)
        val memory = WebAssembly.Memory(1, 1024)
        prepMemory(memory)
        val instance = WebAssembly.Instance(module, makeImportObj(memory))
        instance.exports.call("main")
    }

    def prepMemory(memory: WebAssembly.Memory) {
        val arr = Int32Array(memory.buffer)
        # TODO: pick start values based on amount of static memory used
        # const __HEAP_START_REF = 8 (initialize to 1024)
        # const __HEAP_END_REF = 12 (initialize to 1024)
        arr[2] = 1024
        arr[3] = 1024
    }

    def makeImportObj(memory: WebAssembly.Memory): JSObject {
        val __print: Fn[Int, Unit] = ptr -> {
            if ptr % 4 != 0 {
                throw Error("__print requires 4-byte alignment (got " + ptr + ")")
            }
            val arr = Int32Array(memory.buffer)
            var i = ptr // 4
            val sb = StringBuilder()
            while arr[i] {
                sb.char(arr[i].toChar())
                i++
            }
            IO.println(sb.toString())
        }
        val __debug: Fn[Int, Int, Unit] = (tag, i) -> {
            IO.println([tag, i])
        }
        jsobj!(
            js: jsobj!(memory: memory),
            imports: jsobj!(
                __print: __print,
                __debug: __debug,
            )
        )
    }
}
