package cj

class Test02Numbers {

    @test
    def intOps() = {
        Assert.equal(21 + 42, 63)
        Assert.equal(21 - 42, -21)
        Assert.equal(21 * 42, 882)
        Assert.equal(21 % 42, 21)
        Assert.equal(21 // 42, 0)
        Assert.equal(21 / 42, 0.5)
        Assert.equal(+21, 21)
        Assert.equal(~21, -22)
    }

    class Foo {
        static var staticField : Int = 10
        var instanceField : Int
    }

    @test
    def augassignField() = {
        Assert.equal(Foo.staticField, 10)
        Foo.staticField += 24
        Assert.equal(Foo.staticField, 34)

        val foo = Foo.__malloc(24)
        Assert.equal(foo.instanceField, 24)
        foo.instanceField += 92
        Assert.equal(foo.instanceField, 116)
    }
}
