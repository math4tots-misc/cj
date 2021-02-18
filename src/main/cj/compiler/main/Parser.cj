package compiler.main

import compiler.CJAstInspector
import compiler.CJParser
import cj.FS
import cj.Argv

class Parser {
    def main() {
        val (filename, data) = if Argv() {
            val filename = Argv()[0]
            val data = FS.readFile(filename)
            (filename, data)
        } else {
            ("<stdin>", IO.input())
        }
        IO.println("Parsing " + filename)
        val file = CJParser.parse(filename, data)
        IO.println(CJAstInspector.inspectFile(file))
    }
}
