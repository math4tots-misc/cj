function *cj$List$iterFrom(self, start) {
    for (let i = start; i < self.length; i++) {
        yield self[i];
    }
}
