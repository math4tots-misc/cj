package cj

native class Promise[T?] {
    ## If 'self' will not be awaited on or its value used in any other way,
    ## calling 'done()' indicates to the compiler that this was intentional
    def done(self)

    def then(self, f: Fn[T, Unit]): Promise[Unit]
    def map[R?](self, f: Fn[T, R]): Promise[R]
    def flatMap[R?](self, f: Fn[T, Promise[R]]): Promise[R]
}
