class MC$cj$List {
    constructor(TV$T) {
        this.TV$T = TV$T;
    }
    M$empty() {
        return [];
    }
    M$__new(self) {
        return self;
    }
    M$iter(self) {
        return self[Symbol.iterator]();
    }
    M$size(self) {
        return self.length;
    }
    M$isEmpty(self) {
        return self.length === 0;
    }
    M$add(self, t) {
        self.push(t);
    }
    M$addAll(TV$C, self, ts) {
        for (const t of TV$C.M$iter(ts)) {
            self.push(t);
        }
    }
    M$pop(self) {
        return self.pop();
    }
    M$__getitem(self, i) {
        if (i >= self.length) {
            throw new Error(`Index out of bounds (i = ${i}, len = ${self.length})`);
        }
        return self[i];
    }
    M$__setitem(self, i, t) {
        if (i >= self.length) {
            throw new Error(`Index out of bounds (i = ${i}, len = ${self.length})`);
        }
        self[i] = t;
    }
    M$removeIndex(self, i) {
        return self.splice(i, 1)[0];
    }
    M$insert(self, i, t) {
        self.splice(i, 0, t);
    }
    M$last(self) {
        if (self.length === 0) {
            throw new Error(`Index out of bounds (last() on empty list)`);
        }
        return self[self.length - 1];
    }
    M$swap(self, i, j) {
        const tmp = self[i];
        self[i] = self[j];
        self[j] = tmp;
    }
    M$__slice(self, start, end) {
        return self.slice(start, end);
    }
    M$__sliceFrom(self, start) {
        return self.slice(start);
    }
    M$__sliceTo(self, end) {
        return self.slice(0, end);
    }
    M$__mul(self, n) {
        const ret = [];
        for (let i = 0; i < n; i++) {
            for (const t of self) {
                ret.push(t);
            }
        }
        return ret;
    }
    M$map(TV$R, self, f) {
        return self.map(f);
    }
    M$filter(self, f) {
        return self.filter(f);
    }
    M$clone(self) {
        return Array.from(self);
    }
    M$toBool(self) {
        return self.length !== 0;
    }
    M$toList(self) {
        return Array.from(self);
    }
    M$default() {
        return [];
    }
    M$flatMap(TV$T, TV$C, self, f) {
        const list = [];
        for (const t of self) {
            const c = f(t);
            for (const r of TV$C.M$iter(c)) {
                list.push(r);
            }
        }
        return list;
    }
    M$flatten(TV$I, TV$C, self) {
        return this.M$flatMap(null, TV$C, self, x => x);
    }
    M$__contains(self, t) {
        const TV$T = this.TV$T;
        for (const k of self) {
            if (TV$T.M$__eq(k, t)) {
                return true;
            }
        }
        return false;
    }
    M$sort(self) {
        const TV$T = this.TV$T;
        self.sort((a, b) => TV$T.M$__cmp(a, b));
    }
    M$__eq(self, other) {
        const T = this.TV$T;
        if (self.length !== other.length) {
            return false;
        }
        for (let i = 0; i < self.length; i++) {
            if (!T.M$__eq(self[i], other[i])) {
                return false;
            }
        }
        return true;
    }
    M$hash(self) {
        const T = this.TV$T;
        let hash = 1;
        for (const item of self) {
            hash = combineHash(hash, T.M$hash(item));
        }
        return hash;
    }
    M$approximates(self, other, tolerance) {
        const T = this.TV$T;
        if (self.length !== other.length) {
            return false;
        }
        for (let i = 0; i < self.length; i++) {
            if (!T.M$approximates(self[i], other[i], tolerance)) {
                return false;
            }
        }
        return true;
    }
    M$repr(self) {
        const TV$T = this.TV$T;
        return "[" + self.map(t => TV$T.M$repr(t)).join(", ") + "]";
    }
}
