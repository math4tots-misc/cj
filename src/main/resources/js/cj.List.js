class MC$cj$List {
    constructor(TV$T) {
        this.TV$T = TV$T;
    }
    M$empty() {
        return [];
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
    M$get(self, i) {
        return self[i];
    }
    M$set(self, i, t) {
        self[i] = t;
    }
    M$map(TV$R, self, f) {
        return self.map(f);
    }
    M$filter(self, f) {
        return self.filter(f);
    }
    M$toBool(self) {
        return self.length !== 0;
    }
    M$toList(self) {
        return Array.from(self);
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
    M$repr(self) {
        const TV$T = this.TV$T;
        return "[" + self.map(t => TV$T.M$repr(t)).join(", ") + "]";
    }
}
