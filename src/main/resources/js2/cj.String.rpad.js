function cj$String$rpad(self, length, suffix) {
    while (self.length < length) {
        self += suffix;
    }
    return self;
}
