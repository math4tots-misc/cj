package cj

native class Error {
    def(message: String): Self = js!(Self, "new Error(", message, ")")
    def message(self: Self): String =  js!(String, self, ".message")
}
