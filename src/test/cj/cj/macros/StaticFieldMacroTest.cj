package cj.macros

class StaticFieldMacroTest {

    class Foo {
        static val kwXX = -12
        static val kwAA = 1
        static val kwAB = 2
        static val kwBB = 3
        static val kwC = 55
        static val kwasdf = "hello"
        static val kwAsdf = "world"

        val kwCC = "instance field"
    }

    @test
    def names() {
        Assert.equal(static_field_names!(Foo, "kw[A-Z]+"), ["kwXX", "kwAA", "kwAB", "kwBB", "kwC"])
    }

    @test
    def values() {
        Assert.equal(static_field_values!(Foo, "kw[A-Z]+"), [-12, 1, 2, 3, 55])
        Assert.equal(static_field_values!(Foo, "kw.*[a-z]"), ["hello", "world"])
    }

    @test
    def pairs() {
        Assert.equal(static_field_name_value_pairs!(Foo, "kw[A-Z]+"), [
            ("kwXX", -12),
            ("kwAA", 1),
            ("kwAB", 2),
            ("kwBB", 3),
            ("kwC", 55)])
    }
}
