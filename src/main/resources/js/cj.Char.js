class MC$cj$Char {
    M$toInt(self) {
        return self;
    }
    M$toChar(self) {
        return self;
    }
    M$__eq(self, other) {
        return self === other;
    }
    M$hash(self) {
        return self;
    }
    M$toString(self) {
        return String.fromCodePoint(self);
    }
    M$repr(self) {
        return "'" + String.fromCodePoint(self).replace(/\n|\r|\t|[\x00-\x1E]|"/g, m => {
            switch (m) {
                case '\0': return "\\0";
                case '\n': return "\\n";
                case '\r': return "\\r";
                case '\t': return "\\t";
                case "'": return "\\'";
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
        }) + "'";
    }
    M$size(self) {
        return self < 0x10000 ? 1 : 2;
    }

    M$isDigit(self) {
        return '0'.codePointAt(0) <= self && self <= '9'.codePointAt(0);
    }
    M$isUpper(self) {
        return 'A'.codePointAt(0) <= self && self <= 'Z'.codePointAt(0);
    }
    M$isLower(self) {
        return 'a'.codePointAt(0) <= self && self <= 'z'.codePointAt(0);
    }
    M$isLetter(self) {
        return this.M$isUpper(self) || this.M$isLower(self);
    }
    M$isLetterOrDigit(self) {
        return this.M$isLetter(self) || this.M$isDigit(self);
    }
}
