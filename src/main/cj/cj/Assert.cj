package cj

native class Assert {
    def that[B: ToBool](b: B)
    def equal[T: Eq & Repr](a: T, b: T)
}
