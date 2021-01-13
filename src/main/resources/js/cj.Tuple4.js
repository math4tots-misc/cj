class MC$cj$Tuple4 {
    constructor(TV$A0, TV$A1, TV$A2, TV$A3) {
        this.TV$A0 = TV$A0;
        this.TV$A1 = TV$A1;
        this.TV$A2 = TV$A2;
        this.TV$A3 = TV$A3;
    }
    M$get0(self) {
        return self[0];
    }
    M$get1(self) {
        return self[1];
    }
    M$get2(self) {
        return self[2];
    }
    M$get3(self) {
        return self[3];
    }
    M$__eq(self, other) {
        return (
            this.TV$A0.M$__eq(self[0], other[0])
            && this.TV$A1.M$__eq(self[1], other[1])
            && this.TV$A2.M$__eq(self[2], other[2])
            && this.TV$A3.M$__eq(self[3], other[3])
        );
    }
    M$hash(self) {
        return (
            combineHash(combineHash(combineHash(
                this.TV$A0.M$hash(self[0]),
                this.TV$A1.M$hash(self[1])),
                this.TV$A2.M$hash(self[2])),
                this.TV$A2.M$hash(self[3])));
    }
    M$repr(self) {
        return (
            "(" + this.TV$A0.M$repr(self[0]) +
            ", " + this.TV$A1.M$repr(self[1]) +
            ", " + this.TV$A2.M$repr(self[2]) +
            ", " + this.TV$A2.M$repr(self[3]) +
            ")"
        );
    }
}
