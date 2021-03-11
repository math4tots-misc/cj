function cj$Iterator$fold(self, start, f) {
    for (const t of self) {
        start = f(start, t);
    }
    return start;
}
