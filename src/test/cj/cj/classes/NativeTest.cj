package cj.classes

class NativeTest {

    native class Foo {
        static val foo: String = js!(String, "\"foo field\"")
    }

    @test
    def staticFieldOfNativeClass() {
        Assert.equal(Foo.foo, "foo field")
    }
}
