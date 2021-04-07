package cj.macros

class JSMethodTest {

    @test
    def oneArg() {
        Assert(not jsm!(Bool, "hello", "startsWith", "123"))
        Assert(jsm!(Bool, "hello", "startsWith", "hel"))
    }

     @test
     def multiArg() {
        Assert.equal(jsm!(List[Int], [1], "concat", 55, 72), [1, 55, 72])
    }
}
