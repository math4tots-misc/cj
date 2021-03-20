package cjx.parser

## Generic mark into a file
class Mark: Default, Repr {
    private static val _default: Self = Self("<builtin>", 1, 1)

    ## Path to file
    ## Might not actually be a valid path.
    ## Primarily for diagnostic purposes.
    val filepath: String

    ## Line number .. indexed from 1
    val line: Int

    ## Column number .. indexed from 1
    val column: Int

    def toString(self): String = "in " + filepath + " on " + line + ":" + column
    def repr(self): String = "Mark(" + filepath + ", " + line + ", " + column + ")"
    def default(): Self = _default
}
