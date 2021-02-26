package cjx.jx

import cj.Error
import cj.StringBuilder

## Javascript code generator
class JXJSGen {
    val src: StringBuilder = StringBuilder()
    var sourceRoot = ""
    val sources: List[String] = []
    val names: List[String] = []
    val mapping: StringBuilder = StringBuilder()
    def genSource(self): String = src.toString()
    def genSourceMap(self, outfileName: String): String {
        val sb = StringBuilder()
        sb.add("{\"version\":3,")
        sb.add("\"file\":" + outfileName.repr() + ",")
        sb.add("\"sourceRoot\":" + sourceRoot.repr() + ",")
        sb.add("\"sources\":" + sources + ",")
        sb.add("\"names\":" + names + ",")
        sb.add("\"mapping\":\"")
        sb.add(mapping.toString())
        sb.add("\"}")
        sb.toString()
    }
    def line(self, line: String) {
        Assert.that("\n" not in line)
        src.add(line + "\n")
        mapping.add(";")
    }
    def write(self, s: String) {
        Assert.that("\n" not in s)
        src.add(s)
    }
}
