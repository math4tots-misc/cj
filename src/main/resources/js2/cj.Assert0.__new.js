function cj$Assert0$__new(b, message) {
    if (!b) {
        throw Error(message === '' ? 'Assertion failed' : "Assertion failed: " + message);
    }
}
