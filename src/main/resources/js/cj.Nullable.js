class MC$cj$Nullable {
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
}
