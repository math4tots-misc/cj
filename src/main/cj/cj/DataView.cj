package cj

import cj.ArrayBufferView
import cj.BigInt
import cj.ArrayBuffer

native class DataView: ArrayBufferView {
    def(abuf: ArrayBuffer, useLittleEndian: Bool): Self
    def fromParts(abuf: ArrayBuffer, byteOffset: Int, byteLength: Int): Self
    def useLittleEndian(self, useLittleEndian: Bool)
    def __get_byteOffset(self): Int
    def __get_byteLength(self): Int
    def __get_buffer(self): ArrayBuffer
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
}
