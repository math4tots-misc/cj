package cj

class Test18When {

    union SampleUnion {
        case foo
        case bar
        case x(Int)
        case y(String)
    }

    def ustr(u: SampleUnion): String = when u {
        case foo;case bar = "foo or bar"
        case x(v);case y(v) = v.repr()
    }

    @test
    def sharedBody() {
        Assert.equal(ustr(SampleUnion.foo), "foo or bar")
        Assert.equal(ustr(SampleUnion.bar), "foo or bar")
        Assert.equal(ustr(SampleUnion.x(728)), "728")
        Assert.equal(ustr(SampleUnion.y("some str")), "\"some str\"")
    }
}
