package cj

native class StringBuilder: ToString {
    def new(): Self
    def add(self: Self, string: String)
    def toString(self: Self): String
}
