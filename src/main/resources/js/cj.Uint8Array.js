class MC$cj$Uint8Array {
    M$__new(list) {
        return new Uint8Array(list);
    }
    M$withSize(n) {
        return new Uint8Array(n);
    }
    M$fromIterable(TV$C, c) {
        return new Uint8Array(TV$C.M$iter(c));
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
    M$toArrayBufferView(self) {
        return self;
    }
    M$repr(self) {
        return "Uint8Array(" + Array.from(self).join(", ") + ")";
    }
}