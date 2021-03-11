function cj$BigInt$hash(self) {
    return cj$BigInt$abs(self) <= 0x7FFFFFFF ? Number(self)|0 : cj$String$hash('' + self);
}
