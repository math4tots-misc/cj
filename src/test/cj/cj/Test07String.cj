package cj

class Test07String {
    @test
    def charAndInt() = {
        {
            val i : Int = 'H'
            Assert.equal(i, 72)
            Assert.equal(65, 'A')
            Assert.equal(97, 'a')
        }
    }
}
