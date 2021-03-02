class MC$cjx$js$JSObject {
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
    M$_fromAny(TV$T, t) {
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
    M$_jsCastNullable(TV$T, TV$R, t, cls) {
        if (t === null || t instanceof cls) {
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
    M$isString(self){
        return typeof self === 'string';
    }
    M$toString(self) {
        if (typeof self === 'string') {
            return self;
        } else {
            throw new Error("JSObject.toString on non-string (" + self + ")");
        }
    }
    M$isInt(self) {
        return typeof self === 'number' && (self|0 === self);
    }
    M$toInt(self) {
        if (typeof self === 'number') {
            return self|0;
        } else {
            throw new Error("JSObject.toInt on non-number (" + self + ")");
        }
    }
    M$isDouble(self) {
        return typeof self === 'number';
    }
    M$toDouble(self) {
        if (typeof self === 'number') {
            return self;
        } else {
            throw new Error("JSObject.toInt on non-number (" + self + ")");
        }
    }
}
