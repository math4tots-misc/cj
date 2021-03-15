package cjx.binaryen

import www.wa.WebAssembly
import cjx.binaryen.Binaryen

class BinaryenTest {

    @test
    def sampleAdder() {
        val module = Binaryen.Module()
        val left = module.local.get(0, Binaryen.i32)
        val right = module.local.get(1, Binaryen.i32)
        val add = module.i32.add(left, right)
        val ret = module.return_(add)
        val ii = Binaryen.createType([Binaryen.i32, Binaryen.i32])
        module.addFunction("adder", ii, Binaryen.i32, [], ret)
        module.addFunctionExport("adder", "adder")
        module.optimize()
        val binary = module.emitBinary()
        Assert(module.validate())
        module.dispose()
        val wasm = WebAssembly.Instance(WebAssembly.Module(binary), jsobj!())
        Assert.equal(42, wasm.exports.call("adder", 40, 2).unsafeCast())
    }
}
