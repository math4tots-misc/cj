package cj

native class IO {
    def println[T?: ToString](t: T) = printlnstr(t.toString())
    def print[T?: ToString](t: T)
    def eprintln[T?: ToString](t: T) = eprintlnstr(t.toString())
    def panic[T?: ToString](t: T): NoReturn

    def printlnstr(s: String)
    def eprintlnstr(s: String)

    ## Read all of stdin as a string
    def input(): String
}
