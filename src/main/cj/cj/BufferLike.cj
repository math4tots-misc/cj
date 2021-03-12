package cj

import cj.Uint8Array
import cj.ArrayBuffer

trait BufferLike: Eq {
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
}
