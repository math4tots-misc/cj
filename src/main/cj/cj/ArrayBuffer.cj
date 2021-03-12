package cj

import cj.BufferLike
import cj.ArrayBufferView
import cj.Uint8Array
import cj.ArrayBufferOrView

native class ArrayBuffer: ArrayBufferOrView, Eq, Repr {

    @implicit(Int, _fromInt)
    @implicit(List, _fromList)
    @implicit(BufferLike, _fromView)
    class Convertible {
        val x: ArrayBuffer
        def _fromInt(byteLength: Int): Self = Self(js!(ArrayBuffer, "new ArrayBuffer(", byteLength, ")"))
        def _fromList(bytes: List[Int]): Self = Self(js!(ArrayBuffer, "new Uint8Array(", bytes, ").buffer"))
        def _fromView[V: BufferLike](view: V): Self = Self(
            view.buffer[view.byteOffset:view.byteOffset + view.byteLength])
    }

    def(conv: Convertible): Self = conv.x
    def __get_buffer(self): ArrayBuffer = self
    def __get_byteOffset(self): Int = 0
    def __slice(self, begin: Int, end: Int): Self = js!(Self, self, ".slice(", begin, ",", end, ")")
    def __sliceFrom(self, begin: Int): Self = js!(Self, self, ".slice(", begin, ")")
    def __sliceTo(self, end: Int): Self = js!(Self, self, ".slice(0,", end, ")")

    def set[B: BufferLike](self, other: B, offset: Int) {
        js!(Unit, "new Uint8Array(", self, ").set(new Uint8Array(",
            other.buffer, ",", other.byteOffset, ",", other.byteLength, "),", offset, ")")
    }

    def __eq(self, other: Self): Bool {
        if self is other {
            return true
        }
        if byteLength != other.byteLength {
            return false
        }
        val a = Uint8Array.fromParts(self, 0, byteLength)
        val b = Uint8Array.fromParts(other, 0, byteLength)
        for i = 0; i < a.size(); i++ {
            if a[i] != b[i] {
                return false
            }
        }
        true
    }

    def repr(self): String {
        "ArrayBuffer([" + ", ".join(Uint8Array.fromParts(self, 0, byteLength)) + "])"
    }
}
