class MC$cj$Assert {
    M$that(TV$B, b) {
        if (!TV$B.M$toBool(b)) {
            throw new Error("Assertion failed");
        }
    }
    M$withMessage(TV$B, b, msg) {
        if (!TV$B.M$toBool(b)) {
            throw new Error("Assertion failed: " + msg);
        }
    }
    M$equal(TV$T, a, b) {
        if (!TV$T.M$__eq(a, b)) {
            const astr = TV$T.M$repr(a);
            const bstr = TV$T.M$repr(b);
            throw new Error("Assertion failed: expected " + astr + " to equal " + bstr);
        }
    }
    M$throws(f) {
        let thrown = false;
        const LEN = stack.length;
        try {
            f();
        } catch (e) {
            while (stack.length > LEN) {
                stack.pop();
            }
            thrown = true;
        }
        if (!thrown) {
            throw new Error("Assertion failed: expected excpetion to be thrown");
        }
    }
}
