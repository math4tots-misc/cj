package cj

native class Error {
    def new(message: String): Self
    def message(self: Self): String
}
