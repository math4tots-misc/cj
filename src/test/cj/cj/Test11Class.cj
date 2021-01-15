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

    @test
    def deriveNew() = {
        val d = DeriveNew([], "imfield")
        Assert.equal(d.mutableField, [])
        d.mutableField.add(3)
        Assert.equal(d.mutableField, [3])
        d.mutableField = [5, 6, 7]
        Assert.equal(d.mutableField, [5, 6, 7])
        Assert.equal(d.immutableField, "imfield")
    }

    @derive(new)
    class DeriveNew {
        static val someStaticField : String = "static field here"
        var mutableField : List[Int]
        val immutableField : String
    }

    @test
    def derivePod() = {
        val a = DerivePod([1, 2], "xx")
        Assert.equal(a, DerivePod([1, 2], "xx"))
        Assert.that(a == DerivePod([1, 2], "xx"))
        Assert.that(a != DerivePod([1, 2, 3], "xx"))
        Assert.that(a != DerivePod([1, 2], "yy"))
        Assert.equal("" + a, "DerivePod([1, 2], \"xx\")")
        a.mutableField = [5, 6, 7]
        Assert.equal(a.mutableField, [5, 6, 7])

        val map = Map(a: 3, DerivePod([], "xx"): 7)
        Assert.equal(map.get(a), 3)
    }

    @derive(pod)
    class DerivePod {
        static val someStaticField : String = "another static field here"
        var mutableField : List[Int]
        val immutableField : String
    }
}
