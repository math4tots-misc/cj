package cj

import cj.Approximate
import cj.Assert0

class Assert {
    def[B?: ToBool](b: B) { withMessage(b, "") }
    def that[B?: ToBool](b: B) { Self(b) }
    def withMessage[B?: ToBool](b: B, message: String) { Assert0(b.toBool(), message) }
    def equal[T?: Eq & Repr](a: T, b: T) {
        if a != b {
            Assert0(a == b, "Expected " + a.repr() + " to equal " + b.repr())
        }
    }
    def approximate[T?: Approximate & Repr](a: T, b: T, tolerance: Double) {
    }
    def throws(f: Fn[Unit]) { Assert0.throws(f) }
}
