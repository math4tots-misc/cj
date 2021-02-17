package cj

native class Error {
    def __new(message: String): Self
    def message(self: Self): String
}
