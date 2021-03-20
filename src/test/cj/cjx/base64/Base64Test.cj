package cjx.base64

import cjx.base64.Base64

class Base64Test {
    @test
    def encode() {
        Assert.equal(Base64.encode("".toUTF8()), "")
        Assert.equal(Base64.encode("hello".toUTF8()), "aGVsbG8=")
        Assert.equal(Base64.encode("foobar".toUTF8()), "Zm9vYmFy")
    }
    @test
    def decode() {
        Assert.equal(String.fromUTF8(Base64.decode("")), "")
        Assert.equal(String.fromUTF8(Base64.decode("aGVsbG8=")), "hello")
        Assert.equal(String.fromUTF8(Base64.decode("Zm9vYmFy")), "foobar")
    }
}
