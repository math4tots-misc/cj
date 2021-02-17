package cj

class Test05Nullable {

    @test
    def iter() = {
        val list = null("foo").toList()
        Assert.equal(list, ["foo"])
        Assert.equal(null[String].toList(), [])
    }

    def foo(s: String?): Int? = if null(str) = s { null(str.size()) } else { null }

    @test
    def questionMarkSyntax() {
        Assert.equal(foo(null("hello")), null(5))
    }
}
