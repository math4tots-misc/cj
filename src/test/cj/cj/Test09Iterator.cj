package cj

class Test09Iterator {

    @test
    def flatMap() = {
        {
            val list = [1, 2, 3]
            val newList = list.iter().flatMap(i -> [i * i] * i).toList()
            Assert.equal(newList, [1, 4, 4, 9, 9, 9])
        }
    }
}
