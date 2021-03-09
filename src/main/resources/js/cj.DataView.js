class MC$cj$DataView {
    M$__new(arrayBuffer) {
        return new DataView(arrayBuffer);
    }
    M$fromParts(abuf, begin, end) {
        return new DataView(abuf, begin, end);
    }
    M$useLittleEndian(self, useLittleEndian) {
        self._useLittleEndian = useLittleEndian;
    }
    M$__get_byteLength(self) {
        return self.byteLength;
    }
    M$getInt8(self, byteOffset) {
        return self.getInt8(byteOffset);
    }
    M$getUint8(self, byteOffset) {
        return self.getUint8(byteOffset);
    }
    M$getInt16(self, byteOffset) {
        return self.getInt16(byteOffset, self._useLittleEndian);
    }
    M$getUint16(self, byteOffset) {
        return self.getUint16(byteOffset, self._useLittleEndian);
    }
    M$getInt32(self, byteOffset) {
        return self.getInt32(byteOffset, self._useLittleEndian);
    }
    M$getUint32(self, byteOffset) {
        return self.getUint32(byteOffset, self._useLittleEndian);
    }
    M$getFloat32(self, byteOffset) {
        return self.getFloat32(byteOffset, self._useLittleEndian);
    }
    M$getFloat64(self, byteOffset) {
        return self.getFloat64(byteOffset, self._useLittleEndian);
    }
    M$getBigInt64(self, byteOffset) {
        return self.getBigInt64(byteOffset, self._useLittleEndian);
    }
    M$getBigUint64(self, byteOffset) {
        return self.getBigUint64(byteOffset, self._useLittleEndian);
    }
    M$setInt8(self, byteOffset, value) {
        return self.setInt8(byteOffset, value);
    }
    M$setUint8(self, byteOffset, value) {
        return self.setUint8(byteOffset, value);
    }
    M$setInt16(self, byteOffset, value) {
        return self.setInt16(byteOffset, value);
    }
    M$setUint16(self, byteOffset, value) {
        return self.setUint16(byteOffset, value);
    }
    M$setInt32(self, byteOffset, value) {
        return self.setInt32(byteOffset, value);
    }
    M$setUint32(self, byteOffset, value) {
        return self.setUint32(byteOffset, value);
    }
    M$setFloat32(self, byteOffset, value) {
        return self.setFloat32(byteOffset, value);
    }
    M$setFloat64(self, byteOffset, value) {
        return self.setFloat64(byteOffset, value);
    }
    M$setBigInt64(self, byteOffset, value) {
        return self.setBigInt64(byteOffset, value);
    }
    M$setBigUint64(self, byteOffset, value) {
        return self.setBigUint64(byteOffset, value);
    }
}
