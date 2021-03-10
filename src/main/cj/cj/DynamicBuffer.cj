package cj

import cj.ArrayBuffer
import cj.BigInt

native class DynamicBuffer: Repr, Eq {

    @implicit(ArrayBuffer, fromArrayBuffer)
    class Converter {
        val buffer: DynamicBuffer

        def fromArrayBuffer(abuf: ArrayBuffer): Self = Self(DynamicBuffer.fromArrayBuffer(abuf))
    }

    def(conv: Converter): Self

    def fromArrayBuffer(abuf: ArrayBuffer): Self

    ## Create a new buffer with the given size
    def withSize(n: Int): Self

    ## Create a new empty buffer with the given capacity
    def withCapacity(n: Int): Self

    ## Create an empty new buffer
    def empty(): Self

    ## Converts a string to a UTF-8 DynamicBuffer value
    def fromUTF8(string: String): Self

    @variadic def ofU8s(u8s: List[Int]): Self

    ## Gets the capacity of this buffer in bytes
    def capacity(self: Self): Int

    ## Gets the size of this buffer in bytes
    def size(self: Self): Int

    ## Call to flip to using either little or big endian
    def useLittleEndian(self: Self, flag: Bool)

    ## Sets the new size for the buffer.
    ## The underlying array may be reallocated to acommodate the new size
    def resize(self: Self, newSize: Int)

    def getI8(self: Self, i: Int): Int
    def getU8(self: Self, i: Int): Int
    def getI16(self: Self, i: Int): Int
    def getU16(self: Self, i: Int): Int
    def getI32(self: Self, i: Int): Int
    def getU32(self: Self, i: Int): Double
    def getI64(self: Self, i: Int): BigInt
    def getU64(self: Self, i: Int): BigInt
    def getF32(self: Self, i: Int): Double
    def getF64(self: Self, i: Int): Double
    def getUTF8(self: Self, start: Int, end: Int): String

    def cut(self: Self, start: Int, end: Int): Self
    def cutFrom(self: Self, start: Int): Self

    def setI8(self: Self, i: Int, value: Int)
    def setU8(self: Self, i: Int, value: Int)
    def setI16(self: Self, i: Int, value: Int)
    def setU16(self: Self, i: Int, value: Int)
    def setI32(self: Self, i: Int, value: Int)
    def setU32(self: Self, i: Int, value: Double)
    def setI64(self: Self, i: Int, value: BigInt)
    def setU64(self: Self, i: Int, value: BigInt)
    def setF32(self: Self, i: Int, value: Double)
    def setF64(self: Self, i: Int, value: Double)
    def setBuffer(self: Self, i: Int, other: Self)
    def setUTF8(self: Self, i: Int, string: String)

    def addI8(self: Self, value: Int)
    def addU8(self: Self, value: Int)
    def addI16(self: Self, value: Int)
    def addU16(self: Self, value: Int)
    def addI32(self: Self, value: Int)
    def addU32(self: Self, value: Double)
    def addI64(self: Self, value: BigInt)
    def addU64(self: Self, value: BigInt)
    def addF32(self: Self, value: Double)
    def addF64(self: Self, value: Double)
    def addBuffer(self: Self, other: Self)
    def addUTF8(self: Self, string: String)

    ## Interprets this buffer as a UTF-8 string.
    def toString(self: Self): String = getUTF8(0, size())

    def repr(self: Self): String

    def __eq(self: Self, other: Self): Bool

    def __get_buffer(self): ArrayBuffer
}
