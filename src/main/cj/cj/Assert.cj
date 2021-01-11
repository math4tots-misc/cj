package cj

native class Assert {
    def that[B: ToBool](b: B)
    def withMessage[B: ToBool](b: B, message: String)
    def equal[T?: Eq & Repr](a: T, b: T)
}
