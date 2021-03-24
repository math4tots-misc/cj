class MC$cj$List {
    constructor(TV$T) {
        this.TV$T = TV$T;
    }
    *M$iterFrom(self, start) {
        for (let i = start; i < self.length; i++) {
            yield self[i];
        }
    }
}
