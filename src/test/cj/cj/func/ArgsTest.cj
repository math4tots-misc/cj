package cj.func

class ArgsTest {

    def foo(x: Int = 15): Int = x * x

    def bar(a: String, b: String = "defstr"): String = a + b

    @test
    def defaultArgs() {
        Assert.equal(foo(3), 9)
        Assert.equal(foo(), 15 * 15)
        Assert.equal(bar("aaa", "bbb"), "aaabbb")
        Assert.equal(bar("aaa"), "aaadefstr")
    }
}
