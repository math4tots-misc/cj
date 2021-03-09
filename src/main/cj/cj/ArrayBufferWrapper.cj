package cj

import cj.ArrayBuffer

## Trait for classes that wrap ArrayBuffer
trait ArrayBufferWrapper {
    def __get_buffer(self): ArrayBuffer
}
