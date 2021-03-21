package cjx.notc

import cjx.notc.NCIR
import cjx.notc.NCCodegen
import www.wa.WebAssembly
import cjx.notc.NCParser
import cjx.binaryen.Binaryen
import cj.Uint8Array

class NCCompiler {
    var includePrelude = true

    def compileString(self, string: String): Uint8Array {
        val sources: List[Tuple[String, String]] = []
        # val program = NCIR.Program()
        if includePrelude {
            sources.add(("<prelude>", include_str!("prelude.notc")))
            # NCParser.parse(program, "<prelude>", include_str!("prelude.notc"))
        }
        # NCParser.parse(program, "<string>", string)
        sources.add(("<string>", string))
        val program = NCParser.parseAll(sources)
        NCCodegen.emit(program)
    }

    def compileAndRunMain(self, string: String): Int {
        val binary = compileString(string)
        val module = WebAssembly.Module(binary)
        val instance = WebAssembly.Instance(module, jsobj!())
        instance.exports.call("main").unsafeCast()
    }
}
