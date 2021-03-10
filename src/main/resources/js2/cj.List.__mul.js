function cj$List$__mul(self, n) {
    const ret = [];
    for (let i = 0; i < n; i++) {
        for (const t of self) {
            ret.push(t);
        }
    }
    return ret;
}
