class MC$cj$Bool {
    M$toBool(self) {
        return self;
    }
    M$repr(self) {
        return self ? 'true' : 'false';
    }
    M$__eq(self, other) {
        return self === other;
    }
    M$hash(self) {
        // follow Java's Boolean.hashCode
        return self ? 1231 : 1237;
    }
}
