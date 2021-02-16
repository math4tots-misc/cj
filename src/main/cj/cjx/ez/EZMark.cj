package cjx.ez

@derive(new, repr)
class EZMark: Default {
    private static val _default: Self = Self("<builtin>", 1, 1)

    val filename: String
    val line: Int
    val column: Int

    def toString(self): String = "in " + filename + " on " + line + ":" + column

    def default(): Self = _default
}
