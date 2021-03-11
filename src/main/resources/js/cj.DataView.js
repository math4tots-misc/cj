class MC$cj$DataView {
    M$__new(arrayBuffer, useLittleEndian) {
        return this.M$fromParts(arrayBuffer, 0, arrayBuffer.byteLength, useLittleEndian);
    }
    M$fromParts(abuf, begin, end, useLittleEndian) {
        const dv = new DataView(abuf, begin, end);
        dv._useLittleEndian = useLittleEndian;
        return dv;
    }
    M$useLittleEndian(self, useLittleEndian) {
        self._useLittleEndian = useLittleEndian;
    }
    M$__get_byteOffset(self) {
        return self.byteOffset;
    }
    M$__get_byteLength(self) {
        return self.byteLength;
    }
    M$__get_buffer(self) {
        return self.buffer;
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
        return self.setInt8(byteOffset, value, self._useLittleEndian);
    }
    M$setUint8(self, byteOffset, value) {
        return self.setUint8(byteOffset, value, self._useLittleEndian);
    }
    M$setInt16(self, byteOffset, value) {
        return self.setInt16(byteOffset, value, self._useLittleEndian);
    }
    M$setUint16(self, byteOffset, value) {
        return self.setUint16(byteOffset, value, self._useLittleEndian);
    }
    M$setInt32(self, byteOffset, value) {
        return self.setInt32(byteOffset, value, self._useLittleEndian);
    }
    M$setUint32(self, byteOffset, value) {
        return self.setUint32(byteOffset, value, self._useLittleEndian);
    }
    M$setFloat32(self, byteOffset, value) {
        return self.setFloat32(byteOffset, value, self._useLittleEndian);
    }
    M$setFloat64(self, byteOffset, value) {
        return self.setFloat64(byteOffset, value, self._useLittleEndian);
    }
    M$setBigInt64(self, byteOffset, value) {
        return self.setBigInt64(byteOffset, value, self._useLittleEndian);
    }
    M$setBigUint64(self, byteOffset, value) {
        return self.setBigUint64(byteOffset, value, self._useLittleEndian);
    }
}