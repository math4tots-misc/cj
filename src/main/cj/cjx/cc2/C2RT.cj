package cjx.cc2

import cj.Uint8Array
import www.JSObject
import cj.DataView
import www.wa.WebAssembly
import cjx.cc2.C2MemDesc

## Runtime
class C2RT {
    def newMemory(self, memDesc: C2MemDesc): WebAssembly.Memory {
        val mem = WebAssembly.Memory(memDesc.init, memDesc.max)
        val offset = memDesc.dataOffset
        val data = memDesc.data
        val view = DataView(mem.buffer)
        view.setBuffer(offset, data)
        mem
    }

    def newImportObject(self, memDesc: C2MemDesc): JSObject {
        val mem = newMemory(memDesc)

        val puts: Fn[Int, Int] = start -> {
            val u8arr = Uint8Array(mem.buffer)
            var end = start
            while end < u8arr.size() and u8arr[end] != 0 {
                end++
            }
            val strarr = Uint8Array.fromParts(mem.buffer, start, end - start)
            val str = String.fromUTF8(strarr)
            IO.println(str)
            1
        }

        jsobj!(
            js: jsobj!(
                memory: mem,
            ),
            c: jsobj!(
                puts: puts,
            )
        )
    }
}
