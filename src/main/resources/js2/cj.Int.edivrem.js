function cj$Int$edivrem(a, n) {
    return [(n < 0 ? -1 : 1) * Math.floor(a / Math.abs(n)), a - Math.abs(n) * Math.floor(a / Math.abs(n))];
}
