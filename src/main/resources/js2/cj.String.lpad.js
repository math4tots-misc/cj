function cj$String$lpad(self, length, prefix) {
    while (self.length < length) {
        self = prefix + self;
    }
    return self;
}
