package cj

import cj.DataViewMixin
import cj.Endian
import cj.Uint8Array
import cj.BufferLike
import cj.DataView
import cj.ArrayBuffer
import cj.BigInt

native class DynamicBuffer: Repr, Eq, BufferLike, DataViewMixin {

    @implicit(ArrayBuffer, fromArrayBuffer)
    @implicit(List, fromList)
    @implicit(BufferLike, fromBufferLike)
    @implicit(Int, fromSize)
    class Convertible {
        val x: DynamicBuffer

        def fromArrayBuffer(abuf: ArrayBuffer): Self = Self(DynamicBuffer.fromArrayBuffer(abuf))
        def fromList(u8s: List[Int]): Self = Self(DynamicBuffer.fromArrayBuffer(ArrayBuffer(u8s)))
        def fromBufferLike[B: BufferLike](b: B): Self = Self(
            DynamicBuffer.fromArrayBuffer(ArrayBuffer(b)))
        def fromSize(size: Int): Self = Self(DynamicBuffer.withSize(size))
    }

    def(conv: Convertible): Self = conv.x

    def usingLittleEndian(conv: Convertible): Self { conv.x.endian = Endian.little; conv.x }

    def __get_endian(self): Endian = view.endian
    def __set_endian(self, endian: Endian) { view.endian = endian }

    def fromArrayBufferAndSize(abuf: ArrayBuffer, size: Int): Self = usingArrayBufferAndSize(
        ArrayBuffer(abuf), size)

    def usingArrayBufferAndSize(abuf: ArrayBuffer, size: Int): Self {
        js!(Self, "{view:", DataView(abuf), ",size:", size, "}")
    }

    def fromArrayBuffer(abuf: ArrayBuffer): Self = fromArrayBufferAndSize(abuf, abuf.byteLength)

    ## Create a new buffer with the given size
    def withSize(n: Int): Self = fromArrayBuffer(ArrayBuffer(n))

    ## Create a new empty buffer with the given capacity
    def withCapacity(n: Int): Self = usingArrayBufferAndSize(ArrayBuffer(n), 0)

    ## Create an empty new buffer
    def empty(): Self = fromArrayBuffer(ArrayBuffer(0))

    ## Converts a string to a UTF-8 DynamicBuffer value
    def fromUTF8(string: String): Self = fromArrayBuffer(
        js!(ArrayBuffer, "new TextEncoder().encode(", string, ").buffer"))

    @variadic def ofU8s(u8s: List[Int]): Self = fromArrayBuffer(ArrayBuffer(u8s))

    private def __get_view(self): DataView = js!(DataView, self, ".view")

    ## Gets the capacity of this buffer in bytes
    def capacity(self: Self): Int = view.byteLength

    ## Gets the size of this buffer in bytes
    def size(self: Self): Int = js!(Int, self, ".size")

    ## Sets the new size for the buffer.
    ## The underlying array may be reallocated to acommodate the new size
    def resize(self: Self, newSize: Int) {
        if newSize > capacity() {
            # round (newSize * 2) up to nearest multiple of 8
            val newCap = (newSize * 2 + 7) & (-8)
            val newArrayBuffer = ArrayBuffer(newCap)
            newArrayBuffer.set(toDataView(), 0)
            js!(Unit, self, ".view=", DataView(newArrayBuffer))
        }
        js!(Unit, self, ".size=", newSize)
    }

    def getInt8(self, byteOffset: Int): Int = view.getInt8(byteOffset)
    def getUint8(self, byteOffset: Int): Int = view.getUint8(byteOffset)
    def getInt16(self, byteOffset: Int): Int = view.getInt16(byteOffset)
    def getUint16(self, byteOffset: Int): Int = view.getUint16(byteOffset)
    def getInt32(self, byteOffset: Int): Int = view.getInt32(byteOffset)
    def getUint32(self, byteOffset: Int): Double = view.getUint32(byteOffset)
    def getFloat32(self, byteOffset: Int): Double = view.getFloat32(byteOffset)
    def getFloat64(self, byteOffset: Int): Double = view.getFloat64(byteOffset)
    def getBigInt64(self, byteOffset: Int): BigInt = view.getBigInt64(byteOffset)
    def getBigUint64(self, byteOffset: Int): BigInt = view.getBigUint64(byteOffset)
    def getUTF8(self, start: Int, end: Int): String = js!(
        String, "new TextDecoder().decode(", slicedView(start, end), ")")

    def setInt8(self, byteOffset: Int, value: Int) = view.setInt8(byteOffset, value)
    def setUint8(self, byteOffset: Int, value: Int) = view.setUint8(byteOffset, value)
    def setInt16(self, byteOffset: Int, value: Int) = view.setInt16(byteOffset, value)
    def setUint16(self, byteOffset: Int, value: Int) = view.setUint16(byteOffset, value)
    def setInt32(self, byteOffset: Int, value: Int) = view.setInt32(byteOffset, value)
    def setUint32(self, byteOffset: Int, value: Double) = view.setUint32(byteOffset, value)
    def setFloat32(self, byteOffset: Int, value: Double) = view.setFloat32(byteOffset, value)
    def setFloat64(self, byteOffset: Int, value: Double) = view.setFloat64(byteOffset, value)
    def setBigInt64(self, byteOffset: Int, value: BigInt) = view.setBigInt64(byteOffset, value)
    def setBigUint64(self, byteOffset: Int, value: BigInt) = view.setBigUint64(byteOffset, value)
    def setUTF8(self, start: Int, string: String) {
        # TODO: Determine whether this is safe to do
        setBuffer[ArrayBuffer](start, js!(ArrayBuffer, "new TextEncoder().encode(", string, ").buffer"))
    }
    def setBuffer[B: BufferLike](self, start: Int, buffer: B) {
        slicedView(start, start + buffer.byteLength).set(buffer, 0)
    }

    def addInt8(self, value: Int) { val i = size(); resize(i + 1); view.setInt8(i, value) }
    def addUint8(self, value: Int) { val i = size(); resize(i + 1); IO.debug(view); view.setUint8(i, value) }
    def addInt16(self, value: Int) { val i = size(); resize(i + 2); view.setInt16(i, value) }
    def addUint16(self, value: Int) { val i = size(); resize(i + 2); view.setUint16(i, value) }
    def addInt32(self, value: Int) { val i = size(); resize(i + 4); view.setInt32(i, value) }
    def addUint32(self, value: Double) { val i = size(); resize(i + 4); view.setUint32(i, value) }
    def addFloat32(self, value: Double) { val i = size(); resize(i + 4); view.setFloat32(i, value) }
    def addFloat64(self, value: Double) { val i = size(); resize(i + 8); view.setFloat64(i, value) }
    def addBigInt64(self, value: BigInt) { val i = size(); resize(i + 8); view.setBigInt64(i, value) }
    def addBigUint64(self, value: BigInt) { val i = size(); resize(i + 8); view.setBigUint64(i, value) }
    def addUTF8(self, string: String) {
        addBuffer(js!(ArrayBuffer, "new TextEncoder().encode(", string, ").buffer"))
    }
    def addBuffer[B: BufferLike](self, buffer: B) {
        val i = size()
        resize(i + buffer.byteLength)
        slicedView(i, i + buffer.byteLength).set(buffer, 0)
    }

    # slicing DynamicBuffers always makes a copy of the buffer.
    # This is because you more or less expect a DynamicBuffer to own its buffer.
    # This contrasts with DataViews, which should just create new views into a shared
    # buffer when sliced.

    def __slice(self, start: Int, end: Int): Self = fromArrayBuffer(slicedView(start, end).toArrayBuffer())
    def __sliceFrom(self, start: Int): Self = self[start:size()]
    def __sliceTo(self, end: Int): Self = self[0:end]

    ## Interprets this buffer as a UTF-8 string.
    def toString(self: Self): String = getUTF8(0, size())

    def repr(self: Self): String = "DynamicBuffer([" + ", ".join(Uint8Array(toArrayBuffer())) + "])"

    ## Gets a reference to the underlying ArrayBuffer of this DynamicBuffer.
    ## To get a copy with the same contents, see "toArrayBuffer"
    def __get_buffer(self): ArrayBuffer = view.buffer
    def __get_byteOffset(self): Int = view.byteOffset
    def __get_byteLength(self): Int = size()

    def toArrayBuffer(self): ArrayBuffer = toDataView().toArrayBuffer()
    def toDataView(self): DataView = view[:size()]
    def slicedView(self, start: Int, end: Int): DataView = view[start:end]
    def slicedViewFrom(self, start: Int): DataView = view[start:]
    def slicedViewTo(self, end: Int): DataView = view[:end]
}
