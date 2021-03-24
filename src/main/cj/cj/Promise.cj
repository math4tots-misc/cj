package cj

native class Promise[T?] {
    ## If 'self' will not be awaited on or its value used in any other way,
    ## calling 'done()' indicates to the compiler that this was intentional
    def done(self) = ()

    @generic def then(self, f: Fn[T, Unit]): Promise[Unit] = js!(
        Promise[Unit], self, ".then(", f, ")")
    @generic def map[R?](self, f: Fn[T, R]): Promise[R] = js!(Promise[R], self, ".then(", f, ")")
    @generic def flatMap[R?](self, f: Fn[T, Promise[R]]): Promise[R] = js!(
        Promise[R], self, ".then(", f, ")")
}
