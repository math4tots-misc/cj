package cj

import cj.Uint8Array
import cj.ArrayBuffer
import cj.ArrayBufferOrView

## Marker trait for web API's "ArrayBufferView"
## https://developer.mozilla.org/en-US/docs/Web/API/ArrayBufferView
trait ArrayBufferView: ArrayBufferOrView, Eq {
    def __get_byteLength(self): Int
    def __get_byteOffset(self): Int
    def __get_buffer(self): ArrayBuffer

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
