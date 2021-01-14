package cj

class Test11Class {
    @test
    def multipleFields() = {
        val foo = Foo.__malloc(12, "hi")
        Assert.equal(foo.a, 12)
        Assert.equal(foo.b, "hi")
        foo.b = "world"
        Assert.equal(foo.b, "world")
    }

    class Foo {
        val a: Int
        var b: String
    }
}
