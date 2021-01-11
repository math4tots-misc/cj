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
}
