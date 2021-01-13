class MC$cj$Tuple2 {
    constructor(TV$A0, TV$A1) {
        this.TV$A0 = TV$A0;
        this.TV$A1 = TV$A1;
    }
    M$get0(self) {
        return self[0];
    }
    M$get1(self) {
        return self[1];
    }
    M$__eq(self, other) {
        return this.TV$A0.M$__eq(self[0], other[0]) && this.TV$A1.M$__eq(self[1], other[1]);
    }
    M$hash(self) {
        return combineHash(this.TV$A0.M$hash(self[0]), this.TV$A1.M$hash(self[1]));
    }
    M$repr(self) {
        return "(" + this.TV$A0.M$repr(self[0]) + ", " + this.TV$A1.M$repr(self[1]) + ")";
    }
}
