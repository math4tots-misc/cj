package cj

import cj.Uint8Array
import cj.ArrayBuffer
import cj.ArrayBufferOrView

## Marker trait for web API's "ArrayBufferView"
## https://developer.mozilla.org/en-US/docs/Web/API/ArrayBufferView
trait ArrayBufferView: ArrayBufferOrView {
    def __get_byteOffset(self): Int = js!(Int, self, ".byteOffset")
    def __get_buffer(self): ArrayBuffer = js!(ArrayBuffer, self, ".buffer")
}
