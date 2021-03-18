package cj.macros

class UnionGetMacroTest {

    union Foo {
        case first(Int, Int)
        case second(String, Double)
    }

    @test
    def get() {
        val a = Foo.first(44, 579)
        Assert.equal(get!(a, first, 0), 44)
        Assert.equal(get!(a, first, 1), 579)

        val b = Foo.second("hey", 82.2)
        Assert.equal(get!(b, second, 0), "hey")
        Assert.equal(get!(b, second, 1), 82.2)
    }
}
