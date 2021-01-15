class MC$cj$Char {
    M$toInt(self) {
        return self;
    }
    M$toChar(self) {
        return self;
    }
    M$size(self) {
        return self < 0x10000 ? 1 : 2;
    }
}
