function cj$Float64Array$addWithFactor(self, other, factor) {
    const len = self.length;
    if (len !== other.length) {
        throw new Error(
            `addWithFactor mismatched dimensions (${len}, ${other.length})`);
    }
    for (let i = 0; i < len; i++) {
        self[i] += other[i] * factor;
    }
}
