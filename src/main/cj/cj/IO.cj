package cj

native class IO {
    def println[T: ToString](t: T)
    def eprintln[T: ToString](t: T)
    def panic[T: ToString](t: T): NoReturn
}
