package cjx.notc

import cjx.notc.NCCodegen
import www.wa.WebAssembly
import cjx.notc.NCParser
import cjx.binaryen.Binaryen
import cj.Uint8Array

class NCCompiler {
    def compileString(string: String): Uint8Array {
        val program = NCParser.parse("<string>", string)
        NCCodegen.emit(program)
    }

    def compileAndRunMain(string: String): Int {
        val binary = compileString(string)
        val module = WebAssembly.Module(binary)
        val instance = WebAssembly.Instance(module, jsobj!())
        instance.exports.call("main").unsafeCast()
    }
}
