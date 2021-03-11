package cj

import cj.Uint8Array
import cj.ArrayBufferOrView

native class ArrayBuffer: ArrayBufferOrView, Eq, Repr {
    def(byteLength: Int): Self = js!(Self, "new ArrayBuffer(", byteLength, ")")
    def __get_byteLength(self): Int = js!(Int, self, ".byteLength")
    def __slice(self, begin: Int, end: Int): Self = js!(Self, self, ".slice(", begin, ",", end, ")")
    def __sliceFrom(self, begin: Int): Self = js!(Self, self, ".slice(", begin, ")")
    def __sliceTo(self, end: Int): Self = js!(Self, self, ".slice(0,", end, ")")

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
