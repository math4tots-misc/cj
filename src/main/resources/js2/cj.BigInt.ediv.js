//!! cj.BigInt.floordiv.js
//!! cj.BigInt.abs.js
function cj$BigInt$ediv(a, n) {
    return (n < 0n ? -1n : 1n) * cj$BigInt$floordiv(a, cj$BigInt$abs(n));
}
