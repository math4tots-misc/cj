class MC$cj$Float32Array {
    M$new(list) {
        return new Float32Array(list);
    }
    M$withSize(n) {
        return new Float32Array(n);
    }
    M$fromIterable(TV$C, c) {
        return new Float32Array(TV$C.M$iter(c));
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
    M$map(self, f) {
        const out = this.M$clone(self);
        for (let i = 0; i < out.length; i++) {
            out[i] = f(self[i]);
        }
        return out;
    }
    M$clone(self) {
        return new Float32Array(self);
    }
    M$hash(self) {
        let hash = 1;
        for (const item of self) {
            hash = combineHash(hash, MO$cj$Double.M$hash(item));
        }
        return hash;
    }
    M$__eq(self, other) {
        if (self === other) {
            return true;
        }
        const len = self.length;
        if (len !== other.length) {
            return false;
        }
        for (let i = 0; i < len; i++) {
            if (self[i] !== other[i]) {
                return false;
            }
        }
        return true;
    }
    M$repr(self) {
        return "Float64Array(" + Array.from(self).join(", ") + ")";
    }
}
