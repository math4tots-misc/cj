class MC$cj$js$JSObject {
    M$field(self, key) {
        return self[key];
    }
    M$setField(self, key, value) {
        self[key] = value;
    }
    M$call(self, methodName, args) {
        return self[methodName](...args);
    }
    M$call1(self, methodName, args) {
        return self[methodName](...args);
    }
    M$fromAny(TV$T, t) {
        return t;
    }
    M$instanceof(a, b) {
        return a instanceof b;
    }

    M$_jsCast(t, cls) {
        if (t instanceof cls) {
            return t;
        }
        throw new Error("Expected " + cls.name + " but got " + t.constructor.name);
    }
    M$unsafeCast(self) {
        return self;
    }
}
