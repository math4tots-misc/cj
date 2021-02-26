package cj

class Test16When {

    union Sample {
        case foo(Int, Int, String)
        case bar(String, Double)
    }

    @test
    def dotdot() {
        {
            val x = Sample.foo(5, 7, "hi")
            {
                val (a, b) = when x {
                    case foo(s, r, ..) = (s, r)
                    case bar(..) = (-1, -2)
                }
                Assert.equal(a, 5)
                Assert.equal(b, 7)
            }
            {
                val (a, b) = when Sample.bar("asdf", 24) {
                    case foo(s, r, ..) = (s, r)
                    case bar(..) = (-1, -2)
                }
                Assert.equal(a, -1)
                Assert.equal(b, -2)
            }
        }
    }

    union NoArgUnions {
        case abc
        case foo
    }

    @test
    def noArgUnions() {
        {
            val x = NoArgUnions.abc
            Assert.that(when x {
                case abc = true
                else = false
            })
            Assert.that(when x {
                case foo = false
                case abc = true
            })
            val y = NoArgUnions.foo
            Assert.that(when y {
                case foo = true
                else = false
            })
            Assert.that(when y {
                case foo = true
                case abc = false
            })
        }
    }

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

    def ustr2(u: SampleUnion): String = when u {
        else name(v) = name + "(" + v + ")"
        else = "else (foo or bar)"
    }

    @test
    def elseWithPattern() {
        Assert.equal(ustr2(SampleUnion.foo), "else (foo or bar)")
        Assert.equal(ustr2(SampleUnion.bar), "else (foo or bar)")
        Assert.equal(ustr2(SampleUnion.x(728)), "x(728)")
        Assert.equal(ustr2(SampleUnion.y("some str")), "y(some str)")
    }
}
