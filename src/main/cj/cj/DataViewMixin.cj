package cj

import cj.BufferLike

trait DataViewMixin {
    def getInt8(self, byteOffset: Int): Int
    def getUint8(self, byteOffset: Int): Int
    def getInt16(self, byteOffset: Int): Int
    def getUint16(self, byteOffset: Int): Int
    def getInt32(self, byteOffset: Int): Int
    def getUint32(self, byteOffset: Int): Double
    def getFloat32(self, byteOffset: Int): Double
    def getFloat64(self, byteOffset: Int): Double
    def getBigInt64(self, byteOffset: Int): BigInt
    def getBigUint64(self, byteOffset: Int): BigInt
    def getUTF8(self, start: Int, end: Int): String
    def setInt8(self, byteOffset: Int, value: Int)
    def setUint8(self, byteOffset: Int, value: Int)
    def setInt16(self, byteOffset: Int, value: Int)
    def setUint16(self, byteOffset: Int, value: Int)
    def setInt32(self, byteOffset: Int, value: Int)
    def setUint32(self, byteOffset: Int, value: Double)
    def setFloat32(self, byteOffset: Int, value: Double)
    def setFloat64(self, byteOffset: Int, value: Double)
    def setBigInt64(self, byteOffset: Int, value: BigInt)
    def setBigUint64(self, byteOffset: Int, value: BigInt)
    def setUTF8(self, start: Int, string: String)
    def setBuffer[B: BufferLike](self, start: Int, buffer: B)
}
