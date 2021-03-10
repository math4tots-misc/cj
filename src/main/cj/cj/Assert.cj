package cj

import cj.Approximate

native class Assert {
    def[B?: ToBool](b: B) { withMessage(b, "") }
    def that[B?: ToBool](b: B) { Self(b) }
    def withMessage[B?: ToBool](b: B, message: String) # { withMessage(b.toBool(), message) }
    def equal[T?: Eq & Repr](a: T, b: T) {
        if a != b {
            withMessage(a == b, "Expected " + a.repr() + " to equal " + b.repr())
        }
    }
    def approximate[T?: Approximate & Repr](a: T, b: T, tolerance: Double) {
    }
    def throws(f: Fn[Unit])
    # def[B?: ToBool](b: B)
    # def that[B?: ToBool](b: B)
    # def withMessage[B: ToBool](b: B, message: String)
    # def equal[T?: Eq & Repr](a: T, b: T)
    # def approximate[T?: Approximate & Repr](a: T, b: T, tolerance: Double)
    # def throws(f: Fn[Unit])
}
