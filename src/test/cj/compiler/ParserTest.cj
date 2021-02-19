package compiler

import compiler.CJParser
import compiler.CJAst
import compiler.CJAst.Expr

class ParserTest {

    def parse(string: String): Expr {
        CJParser.parseExpression("<test>", string)
    }

    def parse2(string: String): String {
        parse(string).repr().replace("ExprData.", "")
    }

    @test
    def sampleStr() {
        Assert.equal(
            parse2("\"(\\\\d+\\\\.\\\\d*|\\\\.\\\\d+)(e|E-?\\\\d+)?\""),
            "string(\"(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?\")")
    }

    @test
    def sampleExprs() {
        {
            Assert.equal(
                parse2("hello + world"),
                "call(null, \"__add\", [], [getvar(\"hello\"), getvar(\"world\")])",
            )
            Assert.equal(
                parse2("f(1, 2)"),
                "callname(\"f\", [], [int(1), int(2)])",
            )
            Assert.equal(
                parse2("try { 2.3 } catch t: T {}"),
                "try_(block([double(2.3)]), [Catch(t, T, block([]))], null)",
            )
            Assert.equal(
                parse2("i++"),
                "augvar(\"i\", AugKind.add(), int(1))",
            )
            Assert.equal(
                parse2("(a, b) -> a + b"),
                "lambda(false, [a, b], call(null, \"__add\", [], [getvar(\"a\"), getvar(\"b\")]))",
            )
        }
    }
}
