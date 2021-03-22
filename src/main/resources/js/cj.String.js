class MC$cj$String {
    checkedIndex(self, i) {
        if (i < 0) {
            i += self.length;
        }
        if (i < 0 || i >= self.length) {
            throw new Error(`Index out of bounds (i = ${i}, len = ${self.length})`);
        }
        return i;
    }
    checkedIndex2(self, i) {
        if (i < 0) {
            i += self.length;
        }
        if (i < 0 || i > self.length) {
            throw new Error(`Index out of bounds (i = ${i}, len = ${self.length})`);
        }
        return i;
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
        start = this.checkedIndex2(self, start);
        end = this.checkedIndex2(self, end);
        return self.substring(start, end);
    }
    M$__sliceFrom(self, start) {
        start = this.checkedIndex2(self, start);
        return self.substring(start);
    }
    M$__sliceTo(self, end) {
        end = this.checkedIndex2(self, end);
        return self.substring(0, end);
    }

    M$__mul(self, n) {
        return self.repeat(n);
    }

    M$lpad(self, length, prefix) {
        while (self.length < length) {
            self = prefix + self;
        }
        return self;
    }

    M$rpad(self, length, suffix) {
        while (self.length < length) {
            self += suffix;
        }
        return self;
    }

    M$lstripChar(self, ch) {
        const c = String.fromCodePoint(ch);
        let start = 0;
        while (self.startsWith(c, start)) {
            start += c.length;
        }
        return self.substring(start);
    }

    M$rstripChar(self, ch) {
        const c = String.fromCodePoint(ch);
        let end = self.length;
        while (self.endsWith(c, end)) {
            end -= c.length;
        }
        return self.substring(0, end);
    }

    M$parseInt(string) {
        const i = parseInt(string, 10);
        return isNaN(i) ? null : i;
    }
    M$parseDouble(string) {
        return parseFloat(string);
    }

    M$startsWith(self, prefix) {
        return self.startsWith(prefix);
    }
    M$startsWithAt(self, prefix, startIndex) {
        return self.startsWith(prefix, startIndex);
    }
    M$endsWith(self, suffix) {
        return self.endsWith(suffix);
    }
    M$endsWithAt(self, suffix, endIndex) {
        return self.endsWith(suffix, endIndex);
    }

    M$trim(self) {
        return self.trim();
    }
    M$lower(self) {
        return self.toLowerCase();
    }
    M$upper(self) {
        return self.toUpperCase();
    }
    M$replace(self, old, new_) {
        return self.split(old).join(new_);
    }
    M$split(self, sep) {
        if (sep === "") {
            // This way, surrogate pairs are preserved
            return Array.from(self);
        } else {
            return self.split(sep);
        }
    }

    M$default() {
        return "";
    }
}
