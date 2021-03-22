package cjx.cc

import cjx.cc.CCCodegen
import cjx.cc.CCIR
import cjx.cc.CCError
import cjx.cc.CCParser
import www.wa.WebAssembly
import cj.Uint8Array
import cjx.binaryen.Binaryen

class CCompiler {

    def compileString(string: String): Uint8Array {
        val codegen = CCCodegen()
        val funcs = CCParser.parseFunctions("main", string)
        codegen.emit(funcs)
    }

    def compileAndRunMain(string: String): Int {
        val binary = compileString(string)
        val module = WebAssembly.Module(binary)
        val instance = WebAssembly.Instance(module, jsobj!())
        instance.exports.call("main").unsafeCast()
    }
}
