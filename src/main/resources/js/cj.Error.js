class MC$cj$Error {
    M$new(message) {
        return new Error(message);
    }
    M$message(error) {
        return error.message;
    }
}
