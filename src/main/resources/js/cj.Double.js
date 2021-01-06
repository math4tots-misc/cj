class MC$cj$Double {
    M$repr(x) {
        return '' + x;
    }
    M$__eq(a, b) {
        return a === b;
    }
    M$hash(x) {
        return (10000 * x) | 0;
    }
    M$toBool(self) {
        return !!self;
    }
}
