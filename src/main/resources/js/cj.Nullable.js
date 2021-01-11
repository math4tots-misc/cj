class MC$cj$Nullable {
    constructor(TV$T) {
        this.TV$T = TV$T;
    }
    M$isPresent(self) {
        return self !== null;
    }
    M$isEmpty(self) {
        return self === null;
    }
    M$map(TV$R, self, f) {
        return self === null ? null : f(self);
    }
    M$get(self) {
        if (self === null) {
            throw new Error("get from empty Nullable");
        }
        return self;
    }
    *M$iter(self) {
        if (self !== null) {
            yield self;
        }
    }
    M$__eq(self, other) {
        return self === null ? other === null : (other !== null && this.TV$T.M$__eq(self, other));
    }
    M$repr(self) {
        return self === null ? "null" : ("null(" + this.TV$T.M$repr(self) + ")");
    }
}
