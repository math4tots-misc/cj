package cjx.cc

import cjx.cc.CCIR
import cjx.cc.CCParser

class CCParserTest {

    def parseExpr(s: String): CCIR.Node = CCParser.parseExpression("<test>", s)

    @test
    def exprs() {
        Assert.equal(parseExpr("1+2+3").repr(), "add(add(int(1),int(2)),int(3))")
        # Assert.equal(
        #     parseExpr("int a; int b;a=b=3").repr(), "assign(var(a,0),assign(var(b,1),int(3)))")
    }
}
