Error.stackTraceLimit = 100

const inBrowser = typeof window !== 'undefined';

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

function checkLateinit(x) {
    if (x === undefined) {
        throw new Error("lateinit field used before set");
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

/**
 * Tests whether two numbers are approximately equal
 *
 * In general, this is a tricky problem, but we use some defaults for the casual case
 *
 * @param {number} a
 * @param {number} b
 * @param {number} tolerance
 */
function appx(a, b, tolerance) {
    return Math.abs(a - b) < tolerance
}

class WrappingException extends Error {
    constructor(typeId, data) {
        super(data);
        this.typeId = typeId;
        this.data = data;
    }
}

/**
 * @param {string} string
 */
function stringToArrayBuffer(string) {
    const buffer = new ArrayBuffer(string.length);
    const view = new Uint8Array(buffer);
    for (let i = 0; i < string.length; i++) {
        view[i] = string.charCodeAt(i);
    }
    return buffer;
}

function* iterFrom(self, start) {
    for (let i = start; i < self.length; i++) {
        yield self[i];
    }
}

function* nullIter(self) {
    if (self !== null) {
        yield self;
    }
}

/**
 * @param {string} self
 */
function* strIter(self) {
    for (let i = 0; i < self.length; i++) {
        const c = self.codePointAt(i);
        yield c;
        if (self.charCodeAt(i) !== c) {
            i++;
        }
    }
}

/**
 * Returns number as is, unless it's NaN, in which case it returns null
 * @param {number} x
 */
 function nanToNull(x) {
    return isNaN(x) ? null : x;
}
