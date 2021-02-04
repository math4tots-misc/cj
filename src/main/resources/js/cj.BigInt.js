class MC$cj$BigInt {
    M$new(x) {
        return x;
    }
    M$fromString(s) {
        return BigInt(s);
    }
    M$fromInt(i) {
        return BigInt(i);
    }
    M$fromDouble(f) {
        return BigInt(f);
    }
    M$repr(self) {
        return self + 'n';
    }
    M$toString(self) {
        return '' + self;
    }
    M$__eq(self, other) {
        return self === other;
    }
    M$hash(self) {
        return this.M$abs(self) <= 0x7FFFFFFF ? Number(self)|0 : MO$cj$String.M$hash('' + self);
    }
    M$__pos(self) {
        return self;
    }
    M$__neg(self) {
        return -self;
    }
    M$abs(self) {
        return self < 0 ? -self : self;
    }
    M$__invert(self) {
        return ~self;
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
    M$__rem(self, other) {
        return self % other;
    }
    M$__truncdiv(self, other) {
        return self / other;
    }
    M$__div(self, other) {
        return MO$cj$math$Rational.M$new(self, other);
    }
    M$ipow(self, n) {
        return self ** BigInt(n);
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
    M$ilshift(self, n) {
        return self << BigInt(n);
    }
    M$irshift(self, n) {
        return self >> BigInt(n);
    }
    M$toBool(self) {
        return self !== 0n;
    }
    M$toInt(self) {
        return Number(self)|0;
    }
    M$toDouble(self) {
        return Number(self);
    }
    M$default() {
        return 0n;
    }
    M$isNegative(self) {
        return self < 0;
    }
    M$hex(self) {
        return '0x' + self.toString(16).toUpperCase();
    }

    M$__get_zero() {
        return 0n;
    }
    M$__get_one() {
        return 1n;
    }
    M$edivrem(a, b) {
        return [this.M$ediv(a, b), this.M$erem(a, b)];
    }
    M$ediv(a, n) {
        return (n < 0n ? -1n : 1n) * this.floordiv(a, this.M$abs(n));
    }
    M$erem(a, n) {
        return a - this.M$abs(n) * this.floordiv(a, this.M$abs(n));
    }
    floordiv(a, b) {
        const d = a/b;
        return (a < 0n && b > 0n || a > 0n && b < 0n) && a % b !== 0n ? d - 1n : d;
    }
}

