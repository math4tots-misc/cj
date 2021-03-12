package www.wa.samples

import www.wa.WebAssembly
import cj.ArrayBuffer

class Sample01 {
    static val wasm: ArrayBuffer = include_bytes!("sample01.wasm")

    def main() = amain().done()

    async def amain(): Promise[Unit] {
        val result = WebAssembly.instantiate(wasm, jsobj!()).await
        IO.debug(result.instance.exports.call("add", 5, 7))
    }
}
