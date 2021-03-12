package www.wa

import www.wa.WebAssembly

class WebAssemblyTest {
    @test
    async def add(): Promise[Unit] {
        val result = WebAssembly.instantiate(include_bytes!("add.wasm"), jsobj!()).await
        val instance = result.instance
        val value: Int = result.instance.exports.call("add", 55, 7).unsafeCast()
        Assert.equal(value, 62)
    }
}
