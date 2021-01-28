package cj

native class Promise[T] {
    ## If 'self' will not be awaited on or its value used in any other way,
    ## calling 'done()' indicates to the compiler that this was intentional
    def done(self)
}
