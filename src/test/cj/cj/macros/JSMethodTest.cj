package cj.macros

class JSMethodTest {

    @test
    def sample() {
        Assert(not jsm!(Bool, "hello", "startsWith", "123"))
        Assert(jsm!(Bool, "hello", "startsWith", "hel"))
    }
}
