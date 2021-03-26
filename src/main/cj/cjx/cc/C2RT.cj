package cjx.cc

import cjx.cc.C2Codegen
import cj.Uint8Array
import www.JSObject
import cj.DataView
import www.wa.WebAssembly
import cjx.cc.C2MemDesc

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

    def newImportObject(self, cgr: C2Codegen.Result): JSObject {
        val mem = newMemory(cgr.memDesc)

        val getstr: Fn[Int, String] = start -> {
            val u8arr = Uint8Array(mem.buffer)
            var end = start
            while end < u8arr.size() and u8arr[end] != 0 {
                end++
            }
            val strarr = Uint8Array.fromParts(mem.buffer, start, end - start)
            String.fromUTF8(strarr)
        }

        val puts: Fn[Int, Int] = start -> {
            IO.println(getstr.call(start))
            1
        }

        val __puti: Fn[Int, Int] = i -> {
            IO.println(i)
            1
        }

        val stackTrace: List[Int] = []
        val __push: Fn[Int, Int, Unit] = (fileIndex, lineNumber) -> {
            stackTrace.add(fileIndex)
            stackTrace.add(lineNumber)
        }
        val __pop: Fn[Unit] = () -> stackTrace.pop()
        val getStackTrace: Fn[String] = () -> {
            val parts: List[String] = []
            for i = 0; i < stackTrace.size(); i += 2 {
                val filepath = cgr.filepaths[stackTrace[i]]
                val line = stackTrace[i + 1]
                parts.add("\n  at " + filepath + ":" + line)
            }
            "".join(parts)
        }

        val assert: Fn[Int, Unit] = cond -> if not cond {
            IO.panic("Assertion failed" + getStackTrace.call())
        }

        jsobj!(
            js: jsobj!(
                memory: mem,
            ),
            c: jsobj!(
                puts: puts,
                __puti: __puti,
                assert: assert,
                __push: __push,
                __pop: __pop,
            )
        )
    }
}
