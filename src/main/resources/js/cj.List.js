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
    M$map(TV$R, self, f) {
        return self.map(f);
    }
    M$filter(self, f) {
        return self.filter(f);
    }
    M$toList(self) {
        return Array.from(self);
    }
    M$repr(self) {
        const TV$T = this.TV$T;
        return "[" + self.map(t => TV$T.M$repr(t)).join(", ") + "]";
    }
}
