package cjx.parser

class Mark: Default, Repr {
    private static val _default: Self = Self("<builtin>", 1, 1)

    val filepath: String
    val line: Int
    val column: Int

    def toString(self): String = "in " + filepath + " on " + line + ":" + column
    def repr(self): String = "Mark(" + filepath + ", " + line + ", " + column + ")"
    def default(): Self = _default
}
