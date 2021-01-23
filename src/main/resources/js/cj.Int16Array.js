class MC$cj$Int16Array {
    M$new(list) {
        return new Int16Array(list);
    }
    M$fromIterable(TV$C, c) {
        return new Int16Array(TV$C.M$iter(c));
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
}
