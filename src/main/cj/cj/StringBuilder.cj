package cj

native class StringBuilder: ToString, Default {
    def(): Self
    def default(): Self
    def add(self: Self, string: String)
    def char(self, ch: Char)
    def str(self, str: String)
    def toString(self: Self): String
}
