class MC$cj$JSON {
    M$parse(string) {
        return JSON.parse(string);
    }
    M$fromAny(TV$T, t) {
        return t;
    }
    M$__getitem(TV$K, self, key) {
        return self[key];
    }
    M$__setitem(TV$K, TV$V, self, key, value) {
        self[key] = value;
    }
    M$repr(self) {
        return JSON.stringify(self);
    }
}
