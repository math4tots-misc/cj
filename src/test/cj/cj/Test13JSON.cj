package cj

import cj.JSON

class Test13JSON {
    @test
    def sample() = {
        {
            val json = JSON.parse("[1, 2, 3]")
            Assert.that(json != "hello")
            Assert.that(json != [5])
            Assert.that(json == [1, 2, 3])
        }
        {
            val json = JSON.parse("{\"a\": 3, \"b\": [\"hello\"]}")
            Assert.that(json != Map("a": 3, "b": ["hezllo"]))
            Assert.that(json == Map("a": 3, "b": ["hello"]))
        }
    }
}
