package cj

import cj.Uint8Array
import cj.ArrayBufferOrView

native class ArrayBuffer: ArrayBufferOrView, Eq {
    def(byteLength: Int): Self
    def __get_byteLength(self): Int
    def __slice(self, begin: Int, end: Int): Self
    def __sliceFrom(self, begin: Int): Self
    def __sliceTo(self, end: Int): Self

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
}
