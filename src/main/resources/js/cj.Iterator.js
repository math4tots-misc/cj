class MC$cj$Iterator {
    constructor(TV$T) {
        this.TV$T = TV$T;
    }
    M$iter(i) {
        return i;
    }
    M$next(self) {
        const { done, value } = self.next();
        return done ? null : value;
    }
    M$toList(self) {
        return Array.from(self);
    }

    *M$map(TV$R, self, f) {
        for (const t of self) {
            yield f(t);
        }
    }
    *M$filter(self, f) {
        for (const t of self) {
            if (f(t)) {
                yield t;
            }
        }
    }
    *M$reduce(self, f) {
        const { done, start } = self.next();
        if (done) {
            throw new Error("Reduce on an empty iterator");
        }
        return this.M$fold(this.TV$T, self, start, f);
    }
    *M$fold(TV$R, self, start, f) {
        for (const t of self) {
            start = f(start, t);
        }
        return start;
    }
}
