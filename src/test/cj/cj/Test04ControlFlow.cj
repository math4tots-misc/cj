package cj

import cj.Test01.NestedClass
import cj.Time as Tim
import cj.AIO

class Test04ControlFlow {

    @test
    def while1() = {
        val list = List[Int].empty()
        var i = 6
        while i< 10 {
            list.add(i)
            i = i + 1
        }
        Assert.equal(list, [6, 7, 8, 9])
    }

    @test
    def async_() = {
        Self.sampleAsync()
    }

    async def sampleAsync(): Promise[Unit] = {
        val start = Tim.now()
        AIO.wait(0.05).await
        val end = Tim.now()
        Assert.withMessage(end - start > 0.049, "Test04ControlFlow.async_/sampleAsync")
    }

    @test
    def nullable() = {
        val a = null(10)
        Assert.that(a.isPresent())
        Assert.that(not a.isEmpty())
        Assert.equal(a.get(), 10)
        Assert.equal(a.map(x -> x * x).get(), 100)
        val b = null[Int]
        Assert.that(not b.isPresent())
        Assert.that(b.isEmpty())
        val c: Nullable[String] = null
        Assert.that(not c.isPresent())
        Assert.that(c.isEmpty())
        Assert.that(null[String] != null(""))
        Assert.that(null[String] == null[String])
        Assert.that(null("") == null(""))
    }

    @test
    def nullableTypeArg() = {
        NullableTypeArg[Nullable[String]].__malloc(null)
    }

    # For type parameters: "T?" can also be used as an alias for "@nullable T"
    class NullableTypeArg[@nullable T] {
        val t: T
    }

    @test
    def nestedItem() = {
        Assert.equal(NestedClass.nestedClassVal, "some nested item val")
    }

    @test
    def for1() = {
        val out = List[Int].empty()
        for x in [1, 2, 3] {
            out.add(x * x)
        }
        Assert.equal(out, [1, 4, 9])
    }

    @test
    def forConditions() = {
        {
            val out = List[Int].empty()
            for x in [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] if x < 5 {
                out.add(x)
            }
            Assert.equal(out, [1, 2, 3, 4, 4, 3, 2, 1])
        }
        {
            val out = List[Int].empty()
            for x in [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] if x % 2 == 0 {
                out.add(x)
            }
            Assert.equal(out, [2, 4, 6, 4, 2])
        }
        {
            val out = List[Int].empty()
            for x in [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] while x < 5 {
                out.add(x)
            }
            Assert.equal(out, [1, 2, 3, 4])
        }
        {
            val out = List[Int].empty()
            for x in [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] if x % 2 == 0 while x < 5 {
                out.add(x)
            }
            Assert.equal(out, [2, 4])
        }
    }

    @test
    def classicForLoop() = {
        {
            val out = List[Int].empty()
            for i = 15; i < 20; i += 1 {
                out.add(i)
            }
            Assert.equal(out, [15, 16, 17, 18, 19])
        }
    }
}
