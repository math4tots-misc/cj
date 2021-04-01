package uu

import uu.UUParser
import uu.UULoader

class UULoaderTest {

    def outer(itemName: String): String = UULoader.outerNameRe.match(itemName).get().matchText

    @test
    def regex() {
        Assert.equal(outer("hello.World"), "hello.World")
        Assert.equal(outer("hello.World.Bar"), "hello.World")
        Assert.equal(outer("a.bc.DEF.GHI.JKL"), "a.bc.DEF")
        Assert.equal(outer("a.bc.DEF"), "a.bc.DEF")
    }

    @test
    def sample() {
        {
            val loader = UULoader()
            loader.addFileAst(
                UUParser.parse("<s>", "package a\nclass B{class C{}\nclass D{class E{}}}"))
            loader.addFileAst(
                UUParser.parse("<s>", "package pkg\nclass Foo{class Bar{}}"))
            Assert.equal(loader.load("a.B.D.E").get().item.name, "a.B.D.E")
            Assert.equal(loader.load("a.B").get().item.name, "a.B")
            Assert.equal(loader.load("a.B.C").get().item.name, "a.B.C")
            Assert.equal(loader.load("a.B.D").get().item.name, "a.B.D")
            Assert.equal(loader.load("pkg.Foo").get().item.name, "pkg.Foo")
            Assert.equal(loader.load("pkg.Foo.Bar").get().item.name, "pkg.Foo.Bar")
        }
    }
}
