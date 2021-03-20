package cj

native class StringBuilder: ToString, Default {
    def(): Self = js!(Self, "[]")
    def default(): Self = Self()
    def add(self: Self, string: String) = js!(Unit, self, ".push(", string, ")")
    def char(self, ch: Char) = js!(Unit, self, ".push(String.fromCodePoint(", ch, "))")
    def str(self, str: String) = js!(Unit, self, ".push(", str, ")")
    def toString(self: Self): String = js!(String, self, ".join('')")
}
