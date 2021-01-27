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
        Assert.equal(map[a], 3)
    }

    @derive(pod)
    class DerivePod {
        static val someStaticField : String = "another static field here"
        var mutableField : List[Int]
        val immutableField : String
    }

    @test
    def deriveUnionRepr() = {
        Assert.equal("" + DeriveUnionRepr.foo(94), "DeriveUnionRepr.foo(94)")
        Assert.equal("" + DeriveUnionRepr.bar("abc", 82), "DeriveUnionRepr.bar(\"abc\", 82)")
    }

    @derive(repr)
    union DeriveUnionRepr {
        case foo(Int)
        case bar(String, Int)
    }

    union SimpleUnion {
        case one
        case two
    }

    @test
    def simpleUnion() = {
        {
            val a = SimpleUnion.one()
            val out = when a {
                case one = "ONE"
                case two = "TWO"
            }
            Assert.equal(out, "ONE")
        }
        {
            val a = SimpleUnion.two()
            val out = when a {
                case one = "ONE"
                case two = "TWO"
            }
            Assert.equal(out, "TWO")
        }
    }

    union NonSimpleUnion {
        case one(Int)
        case two(String)
        case three
    }

    @test
    def nonSimpleUnion() = {
        {
            val a = NonSimpleUnion.one(15)
            val out = when a {
                case one(i) = "ONE(" + i + ")"
                case two(s) = "TWO(" + s + ")"
                case three = "THREE"
            }
            Assert.equal(out, "ONE(15)")
        }
        {
            val a = NonSimpleUnion.two("qwer")
            val out = when a {
                case one(i) = "ONE(" + i + ")"
                case two(s) = "TWO(" + s + ")"
                case three = "THREE"
            }
            Assert.equal(out, "TWO(qwer)")
        }
        {
            val a = NonSimpleUnion.three()
            val out = when a {
                case one(i) = "ONE(" + i + ")"
                case two(s) = "TWO(" + s + ")"
                case three = "THREE"
            }
            Assert.equal(out, "THREE")
        }
    }

    @test
    def implicitLocals() = {
        {
            val obj = ImplicitLocals()
            Assert.equal(obj.add(3), 3)
            obj.x = 17
            Assert.equal(obj.add(3), 20)
        }
    }

    @derive(new)
    class ImplicitLocals {
        var x : Int = 0

        def add(self: Self, y: Int) : Int = x + y
    }

    @test
    def staticLateInit() = {
        Assert.throws(() -> StaticLateInit.x)
        StaticLateInit.x = "xxx"
        Assert.equal(StaticLateInit.x, "xxx")
    }

    class StaticLateInit {
        @lateinit static var x : String
    }

    @test
    def nonStaticLateInit() = {
        val obj = NonStaticLateInit()
        Assert.throws(() -> obj.x)
        obj.x = [6, 7, 8]
        Assert.equal(obj.x, [6, 7, 8])
    }

    @derive(new)
    class NonStaticLateInit {
        @lateinit var x : List[Int]
    }

    @test
    def alternativeSyntaxForLateinit() {
        var obj = AlternativeLateinit()
        Assert.throws(() -> obj.y)
        obj.y = 99
        Assert.equal(obj.y, 99)
    }

    @derive(new)
    class AlternativeLateinit {
        var y : Int = ?
    }

    @test
    def inferredFieldType() {
        Assert.equal(InferredFieldType.s, "hello")
    }

    class InferredFieldType {
        static val s = "hello"
    }
}
