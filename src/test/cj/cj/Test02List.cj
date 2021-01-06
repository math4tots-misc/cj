package cj

## Test list operations
class Test02List {

    @test
    def literals() = {
        {
            val list: List[String] = []
            Assert.equal(list.size(), 0)
        }
    }

    @test
    def add() = {
        {
            val list = List[Int].empty()
            Assert.equal(list.size(), 0)
            list.add(15)
            Assert.equal(list, [15])
            Assert.equal(list.get(0), 15)
        }
    }
}
