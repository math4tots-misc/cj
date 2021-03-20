package cjx.cx

import cjx.parser.Mark
import www.sourcemap.JSBuilder

class CXCompiler {
    def compileAndRun(returnCode: Int): Int {
        val jb = JSBuilder()
        # jb.inlineSourceMap = true
        # jb.jsFilePath = "a.js"
        jb.str("(function(){\n'use strict';\n")
        jb.addMark(Mark("<foo>", 1, 3))
        jb.str("function main(){return " + returnCode + "}\n")
        jb.addMark(Mark("<foo>", 3, 3))
        jb.str("return main()")
        jb.str("})()")
        val js = jb.getSource()
        val sm = jb.getSourceMap()
        js!(Int, "eval(", js, ")")
    }
}
