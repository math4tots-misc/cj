class MC$cj$Math {
    M$__get_e() {
        return Math.E;
    }
    M$__get_pi() {
        return Math.PI;
    }
    M$__get_tau() {
        return 2 * Math.PI;
    }
    M$__get_infinity() {
        return Infinity;
    }
    M$random() {
        return Math.random();
    }
    M$floor(x) {
        return Math.floor(x);
    }
    M$ceil(x) {
        return Math.ceil(x);
    }
    M$sin(rad) {
        return Math.sin(rad);
    }
    M$cos(rad) {
        return Math.cos(rad);
    }
    M$tan(rad) {
        return Math.tan(rad);
    }
    M$asin(r) {
        return Math.asin(r);
    }
    M$acos(r) {
        return Math.acos(r);
    }
    M$atan(r) {
        return Math.atan(r);
    }
    M$atan2(y, x) {
        return Math.atan2(y, x);
    }
    M$min(TV$X, a, b) {
        return TV$X.M$__lt(a, b) ? a : b;
    }
    M$max(TV$X, a, b) {
        return TV$X.M$__lt(a, b) ? b : a;
    }
}
