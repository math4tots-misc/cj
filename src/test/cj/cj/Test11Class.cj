package cj

import cj.Test01

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

    @test
    def wrapperClass() = {
        val w = Wrapper.__malloc("hello")
        Assert.equal(w.x, "hello")
    }

    class Wrapper {
        val x: String
    }

    @test
    def referToNestedClass() = {
        Assert.equal(Test01.NestedClass.nestedClassVal, "some nested item val")
    }
}
