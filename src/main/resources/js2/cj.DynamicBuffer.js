/**
 * @typedef {[DataView, boolean, number]} Buf
 * [data, useLittleEndian, size]
 */
class MC$cj$DynamicBuffer {

    M$__new(conv) {
        return conv;
    }

    M$fromArrayBuffer(abuf) {
        return this.fromBuffer(abuf.slice(0));
    }

    /**
     * @param {ArrayBuffer} buffer
     * @returns {Buf}
     */
    fromBuffer(buffer) {
        return this.fromBufferWithEndian(buffer, true);
    }

    /**
     * @param {ArrayBuffer} buffer
     * @param {number} byteOffset
     * @param {number} length
     * @returns {Buf}
     */
    fromBufferSlice(buffer, byteOffset, length) {
        return [new DataView(buffer, byteOffset, length), true, length];
    }

    /**
     * @param {ArrayBuffer} buffer
     * @param {boolean} littleEndian
     * @returns {Buf}
     */
    fromBufferWithEndian(buffer, littleEndian) {
        return [new DataView(buffer), littleEndian, buffer.byteLength];
    }

    /**
     * @param {number} n
     * @returns {Buf}
     */
    M$withSize(n) {
        return this.fromBuffer(new ArrayBuffer(n));
    }
    /**
     * @param {number} n
     * @returns {Buf}
     */
    M$withCapacity(n) {
        return [new DataView(new ArrayBuffer(n)), true, 0];
    }
    /**
     * @returns {Buf}
     */
    M$empty() {
        return this.fromBuffer(new ArrayBuffer(0));
    }
    /**
     * @param {string} string
     */
    M$fromUTF8(string) {
        const typedArray = new TextEncoder().encode(string);
        return this.fromBuffer(typedArray.buffer);
    }
    /**
     * @param {number[]} u8s
     * @returns {Buf}
     */
    M$ofU8s(u8s) {
        return this.fromBuffer(new Uint8Array(u8s).buffer);
    }
    /**
     * @param {Buf} pair
     */
    M$capacity(pair) {
        return pair[0].byteLength;
    }
    /**
     * @param {Buf} pair
     */
    M$size(pair) {
        return pair[2];
    }
    /**
     * @param {Buf} pair
     * @param {boolean} flag
     */
    M$useLittleEndian(pair, flag) {
        pair[1] = flag;
    }
    /**
     * @param {Buf} self
     * @param {number} newSize
     */
    M$resize(self, newSize) {
        bufferSetSize(self, newSize)
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getI8(self, i) {
        return self[0].getInt8(i);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getU8(self, i) {
        return self[0].getUint8(i);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getI16(self, i) {
        return self[0].getInt16(i, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getU16(self, i) {
        return self[0].getUint16(i, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getI32(self, i) {
        return self[0].getInt32(i, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getU32(self, i) {
        return self[0].getUint32(i, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getI64(self, i) {
        return self[0].getBigInt64(i, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getU64(self, i) {
        return self[0].getBigUint64(i, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getF32(self, i) {
        return self[0].getFloat32(i, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     */
    M$getF64(self, i) {
        return self[0].getFloat64(i, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} start
     * @param {number} end
     */
    M$getUTF8(self, start, end) {
        const outerBuf = self[0];
        const buffer = outerBuf.buffer;
        const actualStart = outerBuf.byteOffset + start;
        const length = end - start;
        return new TextDecoder().decode(new Uint8Array(buffer, actualStart, length));
    }
    /**
     * @param {Buf} self
     * @param {number} start
     * @param {number} end
     */
    M$cut(self, start, end) {
        const outerBuf = self[0];
        const buffer = outerBuf.buffer;
        const actualStart = outerBuf.byteOffset + start;
        const length = end - start;
        const arrayBuffer = new ArrayBuffer(end - start);
        new Uint8Array(arrayBuffer).set(new Uint8Array(buffer, actualStart, length));
        return this.fromBufferWithEndian(arrayBuffer, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} start
     */
    M$cutFrom(self, start) {
        return this.M$cut(self, start, self[2]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {number} value
     */
    M$setI8(self, i, value) {
        self[0].setInt8(i, value);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {number} value
     */
    M$setU8(self, i, value) {
        self[0].setUint8(i, value);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {number} value
     */
    M$setI16(self, i, value) {
        self[0].setInt16(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {number} value
     */
    M$setU16(self, i, value) {
        self[0].setUint16(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {number} value
     */
    M$setI32(self, i, value) {
        self[0].setInt32(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {number} value
     */
    M$setU32(self, i, value) {
        self[0].setUint32(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {BigInt} value
     */
    M$setI64(self, i, value) {
        self[0].setBigInt64(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {BigInt} value
     */
    M$setU64(self, i, value) {
        self[0].setBigUint64(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {number} value
     */
    M$setF32(self, i, value) {
        self[0].setFloat32(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {number} value
     */
    M$setF64(self, i, value) {
        self[0].setFloat64(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {Buf} other
     */
    M$setBuffer(self, i, other) {
        new Uint8Array(self[0].buffer).set(new Uint8Array(other[0].buffer, 0, other[2]), i);
    }
    /**
     * @param {Buf} self
     * @param {number} i
     * @param {string} string
     */
    M$setUTF8(self, i, string) {
        new Uint8Array(self[0].buffer).set(new TextEncoder().encode(string), i);
    }
    /**
     * @param {Buf} self
     * @param {number} value
     */
    M$addI8(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 1);
        self[0].setInt8(i, value);
    }
    /**
     * @param {Buf} self
     * @param {number} value
     */
    M$addU8(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 1);
        self[0].setUint8(i, value);
    }
    /**
     * @param {Buf} self
     * @param {number} value
     */
    M$addI16(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 2);
        self[0].setInt16(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} value
     */
    M$addU16(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 2);
        self[0].setUint16(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} value
     */
    M$addI32(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 4);
        self[0].setInt32(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} value
     */
    M$addU32(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 4);
        self[0].setUint32(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {BigInt} value
     */
    M$addI64(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 8);
        self[0].setBigInt64(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {BigInt} value
     */
    M$addU64(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 8);
        self[0].setBigUint64(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} value
     */
    M$addF32(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 4);
        self[0].setFloat32(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {number} value
     */
    M$addF64(self, value) {
        const i = self[2];
        bufferSetSize(self, i + 8);
        self[0].setFloat64(i, value, self[1]);
    }
    /**
     * @param {Buf} self
     * @param {Buf} other
     */
    M$addBuffer(self, other) {
        const i = self[2];
        bufferSetSize(self, i + other[2]);
        this.M$setBuffer(self, i, other);
    }
    /**
     * @param {Buf} self
     * @param {string} string
     */
    M$addUTF8(self, string) {
        this.M$addBuffer(self, this.M$fromUTF8(string));
    }
    /**
     * @param {Buf} self
     */
    M$toString(self) {
        return this.M$getUTF8(self, 0, self[2]);
    }
    /**
     * @param {Buf} self
     */
    M$repr(self) {
        const out = Array.from(new Uint8Array(self[0].buffer, 0, self[2]));
        return "DynamicBuffer.ofU8s(" + out.join(", ") + ")";
    }
    /**
     * @param {Buf} self
     * @param {Buf} other
     */
    M$__eq(self, other) {
        const size = this.M$size(self);
        if (size !== this.M$size(other)) {
            return false;
        }
        for (let i = 0; i < size; i++) {
            if (self[0].getUint8(i) !== other[0].getUint8(i)) {
                return false;
            }
        }
        return true;
    }
    /**
     * @param {Buf} self
     */
    M$__get_buffer(self) {
        return self[0].buffer;
    }
}
/**
 * Sets new size for the buffer, updating the capacity as needed.
 * @param {Buf} pair
 * @param {number} newSize
 */
function bufferSetSize(pair, newSize) {
    if (newSize > pair[0].byteLength) {
        // round (newSize * 2) up to nearest multiple of 8
        const newCap = (newSize * 2 + 7) & (-8);
        const newArrayBuffer = new ArrayBuffer(newCap);
        new Uint8Array(newArrayBuffer).set(new Uint8Array(pair[0].buffer, 0, pair[2]));
        pair[0] = new DataView(newArrayBuffer);
    }
    pair[2] = newSize;
}
const cj$DynamicBuffer = new MC$cj$DynamicBuffer();
