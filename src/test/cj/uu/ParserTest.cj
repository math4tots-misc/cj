package uu

import uu.UUParser
import uu.UUAst.File
import uu.UUAst.Item
import uu.UUAst.Expr

class ParserTest {
    def parse(content: String): File {
        UUParser.parse("<string>", content)
    }

    def parseExpr(expr: String): Expr {
        val file = UUParser.parse("<string>", "package a\nclass B{def c()=(" + expr + ")}")
        file.item.getMethodOrNull("c").get().body.get()
    }

    @test
    def name() {
        val file = parse("package foo\nclass Foo{}")
        Assert.equal(file.packageName, "foo")
        Assert.equal(file.item.shortName, "Foo")
    }

    @test
    def expr() {
        Assert.equal(parseExpr("17").repr(), "{\"kind\":\"int\",\"intValue:\":17}")
    }

    @test
    def sample0() {
        val file = parse(include_str!("psample0.tcj"))
        val item = file.item
        Assert.equal(file.packageName, "sample")
        Assert.equal(item.shortName, "Sample0")
    }
}
