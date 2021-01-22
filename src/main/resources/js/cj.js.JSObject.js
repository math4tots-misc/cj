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

    M$_jsCast(TV$T, TV$R, t, cls) {
        if (t instanceof cls) {
            return t;
        }
        throw new Error("Expected " + cls.name + " but got " + (t ? t.constructor.name : t));
    }
    M$unsafeCast(self) {
        return self;
    }
    M$repr(self) {
        return JSON.stringify(self);
    }
    M$toString(self) {
        if (typeof self === 'string') {
            return self;
        } else {
            throw new Error("JSObject.toString on non-string (" + self + ")");
        }
    }
}