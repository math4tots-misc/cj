package cj

native class Fn2[A0?, A1?, R?] {
    @generic def call(self: Self, a0: A0, a1: A1): R = js!(
        R, self, "(", a0, ",", a1, ")")
}
