/**
 * Combines the hash in a way that is consistent with
 * `java.util.List.hashCode` in the Java language.
 *
 * @param {number} h1
 * @param {number} h2
 */
function combineHash(h1, h2) {
    return (((31 * h1) | 0) + h2) | 0;
}

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

/**
 * tests whether two type objects are equal
 * @param {*} a
 * @param {*} b
 */
function typeEq(a, b) {
    if (a === b) {
        return true;
    }
    if (a.constructor !== b.constructor) {
        return false;
    }
    for (let key in a) {
        if (key.startsWith("TV$")) {
            if (!typeEq(a[key], b[key])) {
                return false;
            }
        }
    }
    return true;
}
