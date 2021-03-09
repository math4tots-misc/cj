package cj

import cj.DataView
import cj.ArrayBuffer
import cj.DynamicBuffer

class Test06DynamicBuffer {

    @test
    def setBuffer() = {
        {
            val buf = DynamicBuffer.ofU8s(5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
            val buf2 = DynamicBuffer.ofU8s(1, 2)
            buf2.addU8(3)
            Assert.equal(buf2, DynamicBuffer.ofU8s(1, 2, 3))
            Assert.equal(buf2.capacity(), 8)
            buf.setBuffer(2, buf2)
            Assert.equal(buf, DynamicBuffer.ofU8s(5, 6, 1, 2, 3, 10, 11, 12, 13, 14, 15))
        }
    }

    @test
    def string() = {
        {
            val buf = DynamicBuffer.fromUTF8("Hello")
            Assert.equal(buf, DynamicBuffer.ofU8s('H', 'e', 'l', 'l', 'o'))
            Assert.equal(buf.size(), 5)
            buf.addUTF8(" world")
            Assert.equal(buf.size(), "Hello world".size())
            Assert.equal(buf.toString(), "Hello world")
            Assert.equal(buf, DynamicBuffer.ofU8s(
                'H', 'e', 'l', 'l', 'o', ' ', 'w', 'o', 'r', 'l', 'd'))
            Assert.equal(72, 'H')
            Assert.equal(buf.getU8(0), 72)
            Assert.equal(buf.getU16(0), 72 + (256 * 'e'))
        }
        Assert.equal(DynamicBuffer.fromUTF8("asdf").repr(), "DynamicBuffer.ofU8s(97, 115, 100, 102)")
    }

    @test
    def fromArrayBuffer() {
        {
            val abuf = ArrayBuffer(32)
            val dv1 = DataView(abuf, true)
            val dbuf = DynamicBuffer(abuf)
            val dv2 = DataView(dbuf.buffer, true)
            dbuf.setU8(0, 14)
            Assert.equal(dbuf.getU16(0), 14)
            Assert.equal(dv1.getUint16(0), 0)
            Assert.equal(dv2.getUint16(0), 14)
        }
    }
}
