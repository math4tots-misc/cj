function cj$Char$isLetter(self) {
    return 'a'.codePointAt(0) <= self && self <= 'z'.codePointAt(0) ||
        'A'.codePointAt(0) <= self && self <= 'Z'.codePointAt(0);
}
