package cjx.cc

import www.wa.WebAssembly
import cj.Uint8Array
import cjx.binaryen.Binaryen

class CCompiler {
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto

    def compileString(string: String): Uint8Array {
        val module = Binaryen.Module()

        val returnCode = string.parseInt().get()
        module.addFunction("main", Binaryen.createType([]), i32, [], module.block(
            null,
            [module.i32.const(returnCode)],
            auto))
        module.addFunctionExport("main", "main")

        module.emitBinary()
    }

    def compileAndRunMain(string: String): Int {
        val binary = compileString(string)
        val module = WebAssembly.Module(binary)
        val instance = WebAssembly.Instance(module, jsobj!())
        instance.exports.call("main").unsafeCast()
    }
}
