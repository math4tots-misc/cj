function cj$JSON$__eq(self, other) {
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
                        if (!cj$JSON$__eq(self[i], other[i])) {
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
                    if (!cj$JSON$__eq(self[keys[i]], other[otherKeys[i]])) {
                        return false;
                    }
                }
                return true;
            }
    }
    throw new Error(`Invalid JSON value: ${self}`)
}
