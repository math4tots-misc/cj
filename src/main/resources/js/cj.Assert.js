class MC$cj$Assert {
    M$throws(f) {
        const stackDefined = typeof stack !== 'undefined';
        let thrown = false;
        const LEN = stackDefined ? stack.length : 0;
        try {
            f();
        } catch (e) {
            if (stackDefined) {
                while (stack.length > LEN) {
                    stack.pop();
                }
            }
            thrown = true;
        }
        if (!thrown) {
            throw new Error("Assertion failed: expected excpetion to be thrown");
        }
    }
}
