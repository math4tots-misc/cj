function *cj$Iterator$map(self, f) {
    for (const t of self) {
        yield f(t);
    }
}
