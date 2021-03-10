/**
 * Asserts that the given value is not undefined
 * @param {*} x
 */
 function defined(x) {
    if (x === undefined) {
        throw new Error("Assertion error");
    }
    return x;
}
