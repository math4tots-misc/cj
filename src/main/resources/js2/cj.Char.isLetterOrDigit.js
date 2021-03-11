function cj$Char$isLetterOrDigit(self) {
    return (
        'a'.codePointAt(0) <= self && self <= 'z'.codePointAt(0) ||
        'A'.codePointAt(0) <= self && self <= 'Z'.codePointAt(0) ||
        '0'.codePointAt(0) <= self && self <= '9'.codePointAt(0));
}
