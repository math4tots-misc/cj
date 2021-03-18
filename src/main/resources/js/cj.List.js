class MC$cj$List {
    constructor(TV$T) {
        this.TV$T = TV$T;
    }
    checkedIndex(self, i) {
        if (i < 0) {
            i += self.length;
        }
        if (i < 0 || i >= self.length) {
            throw new Error(`Index out of bounds (i = ${i}, len = ${self.length})`);
        }
        return i;
    }
    checkedIndex2(self, i) {
        if (i < 0) {
            i += self.length;
        }
        if (i < 0 || i > self.length) {
            throw new Error(`Index out of bounds (i = ${i}, len = ${self.length})`);
        }
        return i;
    }
    *M$iterFrom(self, start) {
        for (let i = start; i < self.length; i++) {
            yield self[i];
        }
    }
    M$__add(self, other) {
        const ret = [];
        for (let i = 0; i < self.length; i++) {
            ret.push(self[i]);
        }
        for (let i = 0; i < other.length; i++) {
            ret.push(other[i]);
        }
        return ret;
    }
    M$__getitem(self, i) {
        i = this.checkedIndex(self, i);
        return self[i];
    }
    M$__setitem(self, i, t) {
        i = this.checkedIndex(self, i);
        self[i] = t;
    }
    M$removeIndex(self, i) {
        i = this.checkedIndex(self, i);
        return self.splice(i, 1)[0];
    }
    M$insert(self, i, t) {
        i = this.checkedIndex2(self, i);
        self.splice(i, 0, t);
    }
    M$last(self) {
        if (!self.length) {
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
        start = this.checkedIndex(self, start);
        end = this.checkedIndex2(self, end);
        return self.slice(start, end);
    }
    M$__sliceFrom(self, start) {
        start = this.checkedIndex(self, start);
        return self.slice(start);
    }
    M$__sliceTo(self, end) {
        end = this.checkedIndex2(self, end);
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
    M$_clearItem(self, i) {
        self[i] = undefined;
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
    M$sortBy(TV$X, self, f) {
        self.sort((a, b) => TV$X.M$__cmp(f(a), f(b)));
    }
    M$_sortByCmp(self, f) {
        self.sort(f);
    }
    M$reverse(self) {
        self.reverse();
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
