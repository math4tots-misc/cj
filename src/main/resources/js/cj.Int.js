class MC$cj$Int {
    M$__new(self) {
        return self;
    }
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
    M$abs(a) {
        return Math.abs(a);
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
    M$__rem(a, b) {
        return (a % b)|0;
    }
    M$__truncdiv(a, b) {
        return (a / b)|0;
    }
    M$__div(a, b) {
        return a / b;
    }
    M$__pow(a, b) {
        return a ** b;
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
    M$__lshift(self, n) {
        return self << n;
    }
    M$__rshift(self, n) {
        return self >> n;
    }
    M$__rshiftu(self, n) {
        return self >>> n;
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
    M$hex(self) {
        return self.toString(16).toUpperCase();
    }
    M$__get_zero() {
        return 0;
    }
    M$__get_one() {
        return 1;
    }
    M$edivrem(a, b) {
        return [this.M$ediv(a, b), this.M$erem(a, b)];
    }
    M$ediv(a, n) {
        return (n < 0 ? -1 : 1) * Math.floor(a / Math.abs(n));
    }
    M$erem(a, n) {
        return a - Math.abs(n) * Math.floor(a / Math.abs(n));
    }
}
