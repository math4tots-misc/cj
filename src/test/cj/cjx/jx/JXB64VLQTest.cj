package cjx.jx

import cjx.jx.JXB64VLQ

class JXB64VLQTest {
    @test
    def samples() {
        Assert.equal(JXB64VLQ.encode(0), "A")
        Assert.equal(JXB64VLQ.encode(1), "C")
        Assert.equal(JXB64VLQ.encode(-1), "D")
        Assert.equal(JXB64VLQ.encode(8), "Q")
        Assert.equal(JXB64VLQ.encode(-81), "jF")
        Assert.equal(JXB64VLQ.encode(137), "yI")
        Assert.equal(JXB64VLQ.encode(1227133512), "wkpykpC")
    }
}
