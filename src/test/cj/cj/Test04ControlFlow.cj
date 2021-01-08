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
}
