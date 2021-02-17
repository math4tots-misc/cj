package cj

native class Error {
    def(message: String): Self
    def message(self: Self): String
}
