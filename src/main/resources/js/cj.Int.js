class MC$cj$Int {
    M$repr(i) {
        return '' + i;
    }
    M$__eq(a, b) {
        return a === b;
    }
    M$hash(i) {
        return i;
    }
    M$__pos(a) {
        return a;
    }
    M$__neg(a) {
        return -a;
    }
    M$__invert(a) {
        return ~a;
    }
    M$__add(a, b) {
        return (a + b)|0;
    }
    M$__sub(a, b) {
        return (a - b)|0;
    }
    M$__mul(a, b) {
        return (a * b)|0;
    }
    M$__mod(a, b) {
        return (a + b)|0;
    }
    M$__rem(a, b) {
        return (a % b)|0;
    }
    M$__truncdiv(a, b) {
        return (a / b)|0;
    }
    M$__div(a, b) {
        return a / b;
    }
    M$__lt(self, other) {
        return self < other;
    }
    M$__or(self, other) {
        return self | other;
    }
    M$__and(self, other) {
        return self & other;
    }
    M$toBool(self) {
        return !!self;
    }
    M$toInt(self) {
        return self;
    }
    M$toDouble(self) {
        return self;
    }
    M$toChar(self) {
        // TODO: check for valid ranges
        return self;
    }
    M$_fromChar(c) {
        return c;
    }
    M$default() {
        return 0;
    }
}
