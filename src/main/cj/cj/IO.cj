package cj

import cj.ToString

native class IO {
    def println[T: ToString](t: T)
}
