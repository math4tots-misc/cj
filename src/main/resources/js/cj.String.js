class MC$cj$String {
    M$toString(s) {
        return s;
    }
    M$repr(x) {
        return '"' + x.replace(/\n|\r|\t|[\x00-\x1E]|"/g, m => {
            switch (m) {
                case '\0': return "\\0";
                case '\n': return "\\n";
                case '\r': return "\\r";
                case '\t': return "\\t";
                case '"': return "\\\"";
                default:
                    const ch = m.codePointAt(0);
                    if (ch < 32) {
                        const rawStr = ch.toString(16);
                        return "\\x" + rawStr.length < 2 ? '0'.repeat(2 - rawStr.length) + rawStr : rawStr;
                    } else {
                        const rawStr = ch.toString(16);
                        return "\\u" + rawStr.length < 4 ? '0'.repeat(4 - rawStr.length) + rawStr : rawStr;
                    }
            }
        }) + '"';
    }
    M$__add(TV$T, a, b) {
        return a + TV$T.M$toString(b);
    }
    M$size(s) {
        return s.length;
    }
    M$toBool(self) {
        return self.length !== 0;
    }
    M$__eq(self, other) {
        return self === other;
    }
    M$hash(self) {
        let h = 0;
        for (const c of self) {
            h = combineHash(h, c.codePointAt(0));
        }
        return h;
    }
    M$join(TV$T, TV$C, self, parts) {
        return Array.from(TV$C.M$iter(parts)).map(t => TV$T.M$toString(t)).join(self);
    }

    M$charCodeAt(self, i) {
        return defined(self.charCodeAt(i));
    }
    M$charAt(self, i) {
        return defined(self.codePointAt(i));
    }
    *M$iter(self) {
        for (let i = 0; i < self.length; i++) {
            const c = self.codePointAt(i);
            yield c;
            if (self.charCodeAt(i) !== c) {
                i++;
            }
        }
    }
    M$__slice(self, start, end) {
        return self.substring(start, end);
    }
    M$__sliceFrom(self, start) {
        return self.substring(start);
    }
    M$__sliceTo(self, end) {
        return self.substring(0, end);
    }

    M$parseInt(string) {
        const i = parseInt(string, 10);
        return isNaN(i) ? null : i;
    }

    M$trim(self) {
        return self.trim();
    }

    M$default() {
        return "";
    }
}
