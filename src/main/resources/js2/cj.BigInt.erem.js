//!! cj.BigInt.floordiv.js
//!! cj.BigInt.abs.js
function cj$BigInt$erem(a, n) {
    return a - cj$BigInt$abs(n) * cj$BigInt$floordiv(a, cj$BigInt$abs(n));
}
