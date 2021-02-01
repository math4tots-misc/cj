class MC$cj$Double {
    M$repr(x) {
        return '' + x;
    }
    M$__eq(a, b) {
        return a === b;
    }
    M$approximates(a, b, tolerance) {
        return appx(a, b, tolerance);
    }
    M$hash(x) {
        return (10000 * x) | 0;
    }
    M$toBool(self) {
        return !!self;
    }
    M$toInt(self) {
        return self|0;
    }
    M$toDouble(self) {
        return self;
    }
    M$_fromInt(i) {
        return i;
    }

    M$__lt(self, other) {
        return self < other;
    }
    M$__add(self, other) {
        return self + other;
    }
    M$__sub(self, other) {
        return self - other;
    }
    M$__mul(self, other) {
        return self * other;
    }
    M$__div(self, other) {
        return self / other;
    }
    M$__rem(self, other) {
        return self % other;
    }
    M$__truncdiv(self, other) {
        return (self / other)|0;
    }
    M$__pow(self, other) {
        return self ** other;
    }
    M$__neg(self) {
        return -self;
    }
    M$abs(self) {
        return Math.abs(self);
    }

    M$toFixed(self, n) {
        return self.toFixed(n);
    }

    M$default() {
        return 0;
    }
}
