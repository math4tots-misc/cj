package cj

import cj.Math
import cj.Uint8Array
import cj.ArrayBuffer

## trait for types that wrap an ArrayBuffer in some way
trait BufferLike: Hash {
    def __get_buffer(self): ArrayBuffer
    def __get_byteOffset(self): Int
    def __get_byteLength(self): Int

    def __eq(self, other: Self): Bool {
        if self is other {
            return true
        }
        if byteLength != other.byteLength {
            return false
        }
        val a = Uint8Array.fromParts(self.buffer, byteOffset, byteLength)
        val b = Uint8Array.fromParts(other.buffer, other.byteOffset, other.byteLength)
        for i = 0; i < a.size(); i++ {
            if a[i] != b[i] {
                return false
            }
        }
        true
    }
    def hash(self): Int {
        var h = 1
        val arr = Uint8Array.fromParts(buffer, byteOffset, byteLength)
        for i = 0; i < arr.size(); i++ {
            h = Math.combineHash(h, arr[i].hash())
        }
        h
    }

    def bytes(self): Iterator[Int] = asUint8Array().iter()

    ## Returns a Uint8Array wrapping the same ArrayBuffer as self
    def asUint8Array(self): Uint8Array = Uint8Array.fromParts(buffer, byteOffset, byteLength)
}
