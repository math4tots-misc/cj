class MC$cj$Int32Array {
    M$__new(list) {
        return new Int32Array(list);
    }
    M$withSize(n) {
        return new Int32Array(n);
    }
    M$fromIterable(TV$C, c) {
        return new Int32Array(TV$C.M$iter(c));
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
    M$default() {
        return this.M$__new([]);
    }
    M$__get_buffer(self) {
        return self.buffer;
    }
    M$repr(self) {
        return "Int32Array(" + Array.from(self).join(", ") + ")";
    }
}
