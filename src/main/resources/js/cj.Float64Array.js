class MC$cj$Float64Array {
    M$new(list) {
        return new Float64Array(list);
    }
    M$withSize(n) {
        return new Float64Array(n);
    }
    M$fromIterable(TV$C, c) {
        return new Float64Array(TV$C.M$iter(c));
    }
    M$iter(self) {
        return self[Symbol.iterator]();
    }
    M$size(self) {
        return self.length;
    }
    M$__getitem(self, i) {
        return self[i];
    }
    M$__setitem(self, i, v) {
        self[i] = v;
    }
    M$toArrayBufferView(self) {
        return self;
    }
}
