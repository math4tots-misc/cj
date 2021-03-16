package cj.classes

class NestedItemsTest {

    class Foo {
        union Kind: Repr {
            case a
            case b
            case c
            case last
            def repr(self): String = tag_name!(self)
        }
    }

    class Bar {
        union Kind: Repr {
            case one
            case two
            case three
            case last
            def repr(self): String = tag_names!(Self)[tag!(self)]
        }
    }

    @test
    def sameNameDifferentItem() {
        val foo: Foo.Kind = Foo.Kind.a
        val bar: Bar.Kind = Bar.Kind.one
        Assert.equal(foo.repr(), "a")
        Assert.equal(bar.repr(), "one")
        val lfoo = Foo.Kind.last
        val lbar = Bar.Kind.last
        Assert.equal(lfoo.repr(), "last")
        Assert.equal(lbar.repr(), "last")
    }
}
