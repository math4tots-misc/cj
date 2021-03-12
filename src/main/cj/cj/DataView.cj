package cj

import cj.ArrayBufferView
import cj.BigInt
import cj.ArrayBuffer

native class DataView: ArrayBufferView {
    def(abuf: ArrayBuffer): Self = fromParts(abuf, 0, abuf.byteLength, false)
    def usingLittleEndian(abuf: ArrayBuffer): Self = fromParts(abuf, 0, abuf.byteLength, true)
    def fromParts(
            abuf: ArrayBuffer,
            byteOffset: Int,
            byteLength: Int,
            useLittleEndian: Bool): Self {
        val dv = js!(Self, "new DataView(", abuf, ",", byteOffset, ",", byteLength, ")")
        js!(Unit, dv, "._useLittleEndian=", useLittleEndian)
        dv
    }
    def useLittleEndian(self, useLittleEndian: Bool) = js!(
        Unit, self, "._useLittleEndian=", useLittleEndian)
    private def _ule(self): Bool = js!(Bool, self, "._useLittleEndian")
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
}
