function *cj$Iterator$_flatMap(self, f) {
    for (const t of self) {
        for (const x of f(t)) {
            yield x;
        }
    }
}
