package cj

import cj.Buffer

class Test06Buffer {
    @test
    def string() = {
        {
            val buf = Buffer.fromUTF8("Hello")
            Assert.equal(buf, Buffer.ofU8s(['H', 'e', 'l', 'l', 'o']))
            Assert.equal(buf.size(), 5)
            buf.addUTF8(" world")
            Assert.equal(buf.size(), "Hello world".size())
            Assert.equal(buf.toString(), "Hello world")
            Assert.equal(buf, Buffer.ofU8s([
                'H', 'e', 'l', 'l', 'o', ' ', 'w', 'o', 'r', 'l', 'd']))
            Assert.equal(72, 'H')
            Assert.equal(buf.getU8(0), 72)
            Assert.equal(buf.getU16(0), 72 + (256 * 'e'))
        }
    }
}
