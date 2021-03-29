class MC$cj$String {
    M$charCodeAt(self, i) {
        return defined(self.charCodeAt(i));
    }
    M$charAt(self, i) {
        return defined(self.codePointAt(i));
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
