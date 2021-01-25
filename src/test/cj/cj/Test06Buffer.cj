package cj

import cj.Buffer

class Test06Buffer {

    @test
    def setBuffer() = {
        {
            val buf = Buffer.ofU8s(5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
            val buf2 = Buffer.ofU8s(1, 2)
            buf2.addU8(3)
            Assert.equal(buf2, Buffer.ofU8s(1, 2, 3))
            Assert.equal(buf2.capacity(), 8)
            buf.setBuffer(2, buf2)
            Assert.equal(buf, Buffer.ofU8s(5, 6, 1, 2, 3, 10, 11, 12, 13, 14, 15))
        }
    }

    @test
    def string() = {
        {
            val buf = Buffer.fromUTF8("Hello")
            Assert.equal(buf, Buffer.ofU8s('H', 'e', 'l', 'l', 'o'))
            Assert.equal(buf.size(), 5)
            buf.addUTF8(" world")
            Assert.equal(buf.size(), "Hello world".size())
            Assert.equal(buf.toString(), "Hello world")
            Assert.equal(buf, Buffer.ofU8s(
                'H', 'e', 'l', 'l', 'o', ' ', 'w', 'o', 'r', 'l', 'd'))
            Assert.equal(72, 'H')
            Assert.equal(buf.getU8(0), 72)
            Assert.equal(buf.getU16(0), 72 + (256 * 'e'))
        }
        Assert.equal(Buffer.fromUTF8("asdf").repr(), "Buffer.ofU8s(97, 115, 100, 102)")
    }
}
