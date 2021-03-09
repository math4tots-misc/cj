package cj

import cj.ArrayBufferView

trait ToArrayBufferView {
    def asArrayBufferView(self: Self): ArrayBufferView
}
