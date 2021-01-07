package cj

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
}
