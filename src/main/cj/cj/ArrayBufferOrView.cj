package cj

import cj.BufferLike
import cj.ArrayBuffer

## Is class ArrayBuffer or has trait ArrayBufferView
##
## Useful for dealing with API that indicate that either ArrayBuffer or
## one of its views is acceptable.
##
trait ArrayBufferOrView: BufferLike {
    def __get_byteLength(self): Int = js!(Int, self, ".byteLength")
}
