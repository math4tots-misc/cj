package cj

import cj.DataViewMixin
import cj.Endian
import cj.BufferLike
import cj.ArrayBufferOrView
import cj.ArrayBufferView
import cj.BigInt
import cj.ArrayBuffer

native class DataView: ArrayBufferView, DataViewMixin {

    def __get_defaultEndian(): Endian = Endian.big

    @implicit(ArrayBuffer, fromArrayBuffer)
    @implicit(BufferLike, fromBufferLike)
    @implicit(DataView, __new)
    class Convertible {
        val x: DataView
        def fromArrayBuffer(abuf: ArrayBuffer): Self = Self(DataView.fromArrayBuffer(abuf))
        def fromBufferLike[V: BufferLike](v: V): Self = Self(DataView.fromParts(
            v.buffer, v.byteOffset, v.byteLength, DataView.defaultEndian))
    }

    def(conv: Convertible): Self = conv.x
    def fromArrayBufferWithEndian(abuf: ArrayBuffer, endian: Endian): Self = fromParts(
        abuf, 0, abuf.byteLength, endian)
    def fromArrayBuffer(abuf: ArrayBuffer): Self = fromArrayBufferWithEndian(abuf, defaultEndian)
    def usingBigEndian(abuf: ArrayBuffer): Self = fromArrayBufferWithEndian(abuf, Endian.big)
    def usingLittleEndian(abuf: ArrayBuffer): Self = fromArrayBufferWithEndian(abuf, Endian.little)
    def fromParts(
            abuf: ArrayBuffer,
            byteOffset: Int,
            byteLength: Int,
            endian: Endian): Self {
        val dv = js!(Self, "new DataView(", abuf, ",", byteOffset, ",", byteLength, ")")
        js!(Unit, dv, "._endian=", endian)
        dv
    }
    def size(self): Int = byteLength
    def __set_endian(self, endian: Endian) = js!(Unit, self, "._endian=", endian)
    def __get_endian(self): Endian = js!(Endian, self, "._endian")
    private def _ule(self): Bool = endian.isLittle()
    def getInt8(self, byteOffset: Int): Int = js!(
        Int, self, ".getInt8(", byteOffset, ",", _ule(), ")")
    def getUint8(self, byteOffset: Int): Int = js!(
        Int, self, ".getUint8(", byteOffset, ",", _ule(), ")")
    def getInt16(self, byteOffset: Int): Int = js!(
        Int, self, ".getInt16(", byteOffset, ",", _ule(), ")")
    def getUint16(self, byteOffset: Int): Int = js!(
        Int, self, ".getUint16(", byteOffset, ",", _ule(), ")")
    def getInt32(self, byteOffset: Int): Int = js!(
        Int, self, ".getInt32(", byteOffset, ",", _ule(), ")")
    def getUint32(self, byteOffset: Int): Double = js!(
        Double, self, ".getUint32(", byteOffset, ",", _ule(), ")")
    def getFloat32(self, byteOffset: Int): Double = js!(
        Double, self, ".getFloat32(", byteOffset, ",", _ule(), ")")
    def getFloat64(self, byteOffset: Int): Double = js!(
        Double, self, ".getFloat64(", byteOffset, ",", _ule(), ")")
    def getBigInt64(self, byteOffset: Int): BigInt = js!(
        BigInt, self, ".getBigInt64(", byteOffset, ",", _ule(), ")")
    def getBigUint64(self, byteOffset: Int): BigInt = js!(
        BigInt, self, ".getBigUint64(", byteOffset, ",", _ule(), ")")
    def getUTF8(self, start: Int, end: Int): String = js!(
        String, "new TextDecoder().decode(", self[start:end], ")")
    def setInt8(self, byteOffset: Int, value: Int) = js!(
        Unit, self, ".setInt8(", byteOffset, ",", value, ",", _ule(), ")")
    def setUint8(self, byteOffset: Int, value: Int) = js!(
        Unit, self, ".setUint8(", byteOffset, ",", value, ",", _ule(), ")")
    def setInt16(self, byteOffset: Int, value: Int) = js!(
        Unit, self, ".setInt16(", byteOffset, ",", value, ",", _ule(), ")")
    def setUint16(self, byteOffset: Int, value: Int) = js!(
        Unit, self, ".setUint16(", byteOffset, ",", value, ",", _ule(), ")")
    def setInt32(self, byteOffset: Int, value: Int) = js!(
        Unit, self, ".setInt32(", byteOffset, ",", value, ",", _ule(), ")")
    def setUint32(self, byteOffset: Int, value: Double) = js!(
        Unit, self, ".setUint32(", byteOffset, ",", value, ",", _ule(), ")")
    def setFloat32(self, byteOffset: Int, value: Double) = js!(
        Unit, self, ".setFloat32(", byteOffset, ",", value, ",", _ule(), ")")
    def setFloat64(self, byteOffset: Int, value: Double) = js!(
        Unit, self, ".setFloat64(", byteOffset, ",", value, ",", _ule(), ")")
    def setBigInt64(self, byteOffset: Int, value: BigInt) = js!(
        Unit, self, ".setBigInt64(", byteOffset, ",", value, ",", _ule(), ")")
    def setBigUint64(self, byteOffset: Int, value: BigInt) = js!(
        Unit, self, ".setBigUint64(", byteOffset, ",", value, ",", _ule(), ")")
    def setUTF8(self, start: Int, string: String) {
        setBuffer(start, js!(ArrayBuffer, "new TextEncoder().encode(", string, ").buffer"))
    }
    def setBuffer[B: BufferLike](self, start: Int, buffer: B) = set(buffer, start)

    def __slice(self, start: Int, end: Int): Self = fromParts(
        buffer, byteOffset + start, end - start, endian)
    def __sliceFrom(self, start: Int): Self = self[start:size()]
    def __sliceTo(self, end: Int): Self = self[0:end]

    def set[B: BufferLike](self, other: B, offset: Int) = asUint8Array().set(other, offset)

    def toArrayBuffer(self): ArrayBuffer {
        val buf = ArrayBuffer(byteLength)
        buf.set(self, 0)
        buf
    }
}
