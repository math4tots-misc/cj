function cj$Char$isDigit(self) {
    return '0'.codePointAt(0) <= self && self <= '9'.codePointAt(0);
}
