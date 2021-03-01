package cjx.js.sourcemap

import cjx.js.sourcemap.JSB64VLQ

class JSB64VLQTest {
    @test
    def samples() {
        Assert.equal(JSB64VLQ.encode(0), "A")
        Assert.equal(JSB64VLQ.encode(1), "C")
        Assert.equal(JSB64VLQ.encode(-1), "D")
        Assert.equal(JSB64VLQ.encode(8), "Q")
        Assert.equal(JSB64VLQ.encode(-81), "jF")
        Assert.equal(JSB64VLQ.encode(137), "yI")
        Assert.equal(JSB64VLQ.encode(1227133512), "wkpykpC")
    }
}
