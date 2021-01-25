package cj

class Test14Default {

    @test
    def derive() = {
        val dd = DeriveDefault.default()
        Assert.equal(dd.i, 0)
        Assert.equal(dd.list, [])
    }

    @derive(default)
    class DeriveDefault {
        val i : Int
        val list : List[String]
    }
}
