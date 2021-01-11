package cj

class Test05Nullable {

    @test
    def iter() = {
        val list = null("foo").toList()
        Assert.equal(list, ["foo"])
        Assert.equal(null[String].toList(), [])
    }
}
