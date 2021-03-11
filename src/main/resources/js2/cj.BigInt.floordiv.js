function cj$BigInt$floordiv(a, b) {
    const d = a/b;
    return (a < 0n && b > 0n || a > 0n && b < 0n) && a % b !== 0n ? d - 1n : d;
}
