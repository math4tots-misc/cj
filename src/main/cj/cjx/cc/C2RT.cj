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

        val __putsi: Fn[Int, Int, Int] = (ptr, i) -> {
            IO.println(getstr.call(ptr) + i)
            1
        }

        val stackTrace: List[Int] = []
        val __push: Fn[Int, Int, Int, Unit] = (funcNameIndex, fileNameIndex, lineNumber) -> {
            stackTrace.add(funcNameIndex)
            stackTrace.add(fileNameIndex)
            stackTrace.add(lineNumber)
        }
        val __pop: Fn[Unit] = () -> { stackTrace.pop(); stackTrace.pop(); stackTrace.pop() }
        val getStackTrace: Fn[String] = () -> {
            var lastFileIndex = -1
            var lastLine = -1
            val parts: List[String] = []
            for i = 0; i < stackTrace.size(); {
                val funcNameIndex = stackTrace[i]
                val fileNameIndex = stackTrace[i + 1]
                val funcName = cgr.names[funcNameIndex]
                val filepath = cgr.names[fileNameIndex]
                val line = stackTrace[i + 2]
                # NOTE: Due to the way we generate stack traces, we may see
                # large number of duplicate stack trace entries.
                # So here, we collapse consecutive duplicate
                i += 3
                var rep = 1
                while (i + 3 < stackTrace.size() and
                        stackTrace[i] == funcNameIndex and
                        stackTrace[i + 1] == fileNameIndex and
                        stackTrace[i + 2] == line) {
                    i += 3
                    rep++
                }
                parts.add("\n  in " + funcName + " (" + filepath + ":" + line + ")")
                if rep > 1 {
                    parts.add(" (x" + rep + ")")
                }
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
                __putsi: __putsi,
                assert: assert,
                __push: __push,
                __pop: __pop,
            )
        )
    }
}
