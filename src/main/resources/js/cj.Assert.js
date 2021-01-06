class MC$cj$Assert {
    M$that(TV$B, b) {
        if (!TV$B.M$toBool(b)) {
            throw new Error("Assertion failed");
        }
    }
    M$equal(TV$T, a, b) {
        if (!TV$T.M$__eq(a, b)) {
            const astr = TV$T.M$repr(a);
            const bstr = TV$T.M$repr(b);
            throw new Error("Assertion failed: expected " + astr + " to equal " + bstr);
        }
    }
}
