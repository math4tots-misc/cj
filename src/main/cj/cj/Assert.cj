package cj

import cj.Approximate

native class Assert {
    def that[B?: ToBool](b: B)
    def withMessage[B: ToBool](b: B, message: String)
    def equal[T?: Eq & Repr](a: T, b: T)
    def approximate[T?: Approximate & Repr](a: T, b: T, tolerance: Double)
    def throws(f: Fn[Unit])
}
