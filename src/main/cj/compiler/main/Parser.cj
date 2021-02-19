package compiler.main

import compiler.CJAstInspector
import compiler.CJParser
import cj.FS
import cj.Argv

class Parser {
    def main() {
        val argv = Argv()
        for filename in argv {
            val data = FS.readFile(filename)
            IO.println("Parsing " + filename)
            val file = CJParser.parse(filename, data)
            IO.println(CJAstInspector.inspectFile(file))
        }
    }
}
