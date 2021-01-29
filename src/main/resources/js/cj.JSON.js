class MC$cj$JSON {
    M$new(self) {
        return self;
    }
    M$parse(string) {
        return JSON.parse(string);
    }
    M$_unsafeCast(TV$T, t) {
        return t;
    }
    M$_fromUnit(unit) {
        return null;
    }
    M$_fromList(list) {
        return list;
    }
    M$_fromMap(map) {
        const M = new MC$cj$Map(MO$cj$String, MO$cj$JSON);
        const obj = {};
        for (const [key, value] of M.M$pairs(map)) {
            obj[key] = value;
        }
        return obj;
    }
    M$object(pairs) {
        const obj = {};
        for (const [key, value] of pairs) {
            obj[key] = value;
        }
        return obj;
    }
    M$__getitem(self, key) {
        if (typeof self !== 'object') {
            throw new Error("JSON.__getitem on non-object");
        }
        return self[key];
    }
    M$__setitem(self, key, value) {
        if (typeof self !== 'object') {
            throw new Error("JSON.__setitem on non-object");
        }
        self[key] = value;
    }
    M$repr(self) {
        return JSON.stringify(self);
    }
    M$type(self) {
        switch (typeof self) {
            case 'number':
                return 0;
            case 'string':
                return 1;
            case 'boolean':
                return 2;
            case 'object':
                return self === null ? 3 : Array.isArray(self) ? 4 : 5;
        }
        throw new Error(`Invalid JSON value: ${self}`);
    }
    M$__eq(self, other) {
        switch (typeof self) {
            case 'number':
            case 'string':
            case 'boolean':
                return self === other;
            case 'object':
                if (self === other) {
                    return true;
                } else if (self === null || other === null || typeof other !== 'object') {
                    return false;
                } else if (Array.isArray(self) || Array.isArray(other)) {
                    if (!Array.isArray(self) || !Array.isArray(other)) {
                        return false;
                    } else if (self.length !== other.length) {
                        return false;
                    } else {
                        for (let i = 0; i < self.length; i++) {
                            if (!this.M$__eq(self[i], other[i])) {
                                return false;
                            }
                        }
                        return true;
                    }
                } else {
                    const keys = Object.keys(self).sort();
                    const otherKeys = Object.keys(other).sort();
                    if (keys.length !== otherKeys.length) {
                        return false;
                    }
                    for (let i = 0; i < keys.length; i++) {
                        if (keys[i] !== otherKeys[i]) {
                            return false;
                        }
                    }
                    for (let i = 0; i < keys.length; i++) {
                        if (!this.M$__eq(self[keys[i]], other[otherKeys[i]])) {
                            return false;
                        }
                    }
                    return true;
                }
        }
        throw new Error(`Invalid JSON value: ${self}`)
    }
    M$isNull(self) {
        return self === null;
    }
    M$isBool(self) {
        return typeof self === 'boolean';
    }
    M$getBool(self) {
        if (typeof self !== 'boolean') {
            throw new Error('JSON.getBool on non-bool')
        }
        return self;
    }
    M$isNumber(self) {
        return typeof self === 'number'
    }
    M$getInt(self) {
        if (typeof self !== 'number') {
            throw new Error('JSON.getInt on non-number');
        }
        return self|0;
    }
    M$getDouble(self) {
        if (typeof self !== 'number') {
            throw new Error('JSON.getDouble on non-number');
        }
        return self;
    }
    M$isString(self) {
        return typeof self === 'string';
    }
    M$getString(self) {
        if (typeof self !== 'string') {
            throw new Error('JSON.getString on non-string');
        }
        return self;
    }
    M$isList(self) {
        return Array.isArray(self);
    }
    M$isObject(self) {
        return typeof self === 'object' && !Array.isArray(self);
    }
    M$toFloat32Array(self) {
        return Float32Array.from(self);
    }
    M$toFloat64Array(self) {
        return Float64Array.from(self);
    }
}
