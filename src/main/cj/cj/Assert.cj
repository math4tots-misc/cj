package cj

import cj.Error
import cj.Approximate

native class Assert {
    def[B?: ToBool](b: B) { if not b { throw Error("Assertion failed") } }
    def that[B?: ToBool](b: B) { Self(b) }
    def withMessage[B?: ToBool](b: B, message: String) {
        if not b { throw Error("Assertion failed: " + message) }
    }
    def equal[T?: Eq & Repr](a: T, b: T) {
        if a == b {
            throw Error("Expected " + a.repr() + " to equal " + b.repr())
        }
    }
    def approximate[T?: Approximate & Repr](a: T, b: T, tolerance: Double) {
        if not a.approximates(b, tolerance) {
            throw Error("Assertion failed: Expected " + a.repr() + " to approximate " + b.repr())
        }
    }
    def throws(f: Fn[Unit])
}
