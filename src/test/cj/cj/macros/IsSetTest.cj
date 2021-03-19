package cj.macros

class IsSetTest {

    class Foo {
        static var staticFoo: Int = ?
        var nonStaticFoo: String = ?
    }

    @test
    def staticField() {
        Assert.that(not is_set!(Foo, staticFoo))
        Foo.staticFoo = 2837
        Assert.that(is_set!(Foo, staticFoo))
        Assert.equal(Foo.staticFoo, 2837)

        val foo = Foo()
        Assert.that(not is_set!(foo, nonStaticFoo))
        foo.nonStaticFoo = "hello world"
        Assert.that(is_set!(foo, nonStaticFoo))
        Assert.equal(foo.nonStaticFoo, "hello world")
    }
}
