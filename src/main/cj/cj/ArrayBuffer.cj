package cj

import cj.ArrayBufferOrView

native class ArrayBuffer: ArrayBufferOrView {
    def(byteLength: Int): Self
    def __get_byteLength(self): Int
    def __slice(self, begin: Int, end: Int): Self
    def __sliceFrom(self, begin: Int): Self
    def __sliceTo(self, end: Int): Self
}
