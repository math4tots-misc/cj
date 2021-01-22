class MC$cj$JSON {
    M$parse(string) {
        return JSON.parse(string);
    }
    M$object(pairs) {
        const obj = {};
        for (const [key, value] of pairs) {
            obj[key] = value;
        }
        return obj;
    }
    M$fromAny(TV$T, t) {
        switch (TV$T) {
            case MO$cj$JSON:
            case MO$cj$Int:
            case MO$cj$Double:
            case MO$cj$Bool:
            case MO$cj$String:
                return t;
            case MO$cj$Unit:
                return null;
            default:
                if (TV$T.constructor === MC$cj$List) {
                    const inner = TV$T.TV$T;
                    switch (inner) {
                        case MO$cj$JSON:
                        case MO$cj$Int:
                        case MO$cj$Double:
                        case MO$cj$Bool:
                        case MO$cj$String:
                            return t;
                    }
                    return t.map(a => this.M$fromAny(null, a));
                }
        }
        throw new Error(`Invalid type for JSON.fromAny: ${TV$T.constructor}`);
    }
    M$__getitem(self, key) {
        return self[key];
    }
    M$__setitem(self, key, value) {
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
}
