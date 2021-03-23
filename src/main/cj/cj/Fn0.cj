package cj

native class Fn0[R?] {
    @generic def call(self: Self): R = js!(R, self, "()")
}
