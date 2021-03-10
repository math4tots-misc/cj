function cj$Assert$withMessage(b, message) {
    if (!b) {
        throw Error(message === '' ? 'Assertion failed' : "Assertion failed: " + message);
    }
}
