function cj$Float32Array$scale(self, factor) {
    const len = self.length;
    for (let i = 0; i < len; i++) {
        self[i] *= factor;
    }
}