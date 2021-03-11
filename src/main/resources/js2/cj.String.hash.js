function cj$String$hash(self) {
    let h = 0;
    for (const c of self) {
        h = cj$Math$combineHash(h, c.codePointAt(0));
    }
    return h;
}
