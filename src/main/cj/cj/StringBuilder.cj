package cj

native class StringBuilder: ToString {
    def(): Self
    def add(self: Self, string: String)
    def toString(self: Self): String
}
