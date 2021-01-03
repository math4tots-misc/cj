class MC$cj$List {
    constructor(TV$T) {
        this.TV$T = TV$T;
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
}
