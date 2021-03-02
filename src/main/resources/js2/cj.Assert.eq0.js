function asserteq0(a, b) {
    if (a !== b) {
        throw Error("Expected " + a + " to equal " + b);
    }
}
