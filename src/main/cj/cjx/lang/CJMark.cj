package cjx.lang

@derive(new, repr)
class CJMark : Default {
    private static val _default : CJMark = Self("<builtin>", 1, 1)

    val filename: String
    val line: Int
    val column: Int

    def toString(self): String = "in " + filename + " on " + line + ":" + column

    def default(): Self = _default
}
