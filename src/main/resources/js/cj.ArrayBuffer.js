class MC$cj$ArrayBuffer {
    M$__new(byteLength) {
        return new ArrayBuffer(byteLength);
    }
    M$__get_byteLength(self) {
        return self.byteLength;
    }
    M$__slice(self, begin, end) {
        return self.slice(begin, end);
    }
    M$__sliceFrom(self, begin) {
        return self.slice(begin);
    }
    M$__sliceTo(self, end) {
        return self.slice(0, end);
    }
}
