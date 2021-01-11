package cj

import cj.Time
import cj.AIO

class Test04ControlFlow {

    @test
    def while1() = {
        val list = List[Int].empty()
        var i = 6
        while i < 10 {
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
        val start = Time.now()
        AIO.wait(0.05).await
        val end = Time.now()
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
    }

    @test
    def nullableTypeArg() = {
        NullableTypeArg[Nullable[String]].__malloc(null)
    }

    @nullable
    class NullableTypeArg[T?] {
        val t: T
    }
}
