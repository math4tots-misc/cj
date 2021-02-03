package cjx.lang

@derive(new, repr)
class CJMark {
    val filename: String
    val line: Int
    val column: Int

    def toString(self): String = "in " + filename + " on " + line + ":" + column
}
