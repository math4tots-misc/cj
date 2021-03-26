package cjx.cc

import cjx.cc.C2Compiler

class C2CompilerTest {
    static val compiler: C2Compiler = {
        val c = C2Compiler()
        c.includePrelude = false
        c
    }

    def runIntExpr(expr: String): Int = compiler.run(
        "<string>", "int main(){return " + expr + ";}")

    def assertExpr(expr: String, code: Int) {
        Assert.equal(runIntExpr(expr), code)
    }

    def assertStmt(stmts: String, code: Int) {
        Assert.equal(compiler.run("<string>", "int main(){" + stmts + "}"), code)
    }

    def assertFns(fns: String, code: Int) {
        Assert.equal(compiler.run("<string>", fns), code)
    }

    @test
    def sample0A() {
        assertExpr("5", 5)
    }

    @test
    def sample0B() {
        compiler.includePrelude = false
        compiler.run("sample0.c", include_str!("sample0.c"))
    }

    @test
    def testsA() {
        compiler.includePrelude = false
        compiler.run("testsA.c", include_str!("testsA.c"))
    }

    @test
    def testsB() {
        compiler.includePrelude = false
        compiler.run("testsB.c", include_str!("testsB.c"))
    }

    @test
    def func() {
        assertFns("int foo() { return 5; } int main() { return foo(); }", 5)
        assertFns("int add(int a, int b) { return a + b; } int main() { return add(3, 17); }", 20)
    }

    @test
    def globalVars() {
        assertFns("int x; int main() { return x; }", 0)
        assertFns("int x; int main() { x=3; return x; }", 3)
        assertFns("int x; int y; int main() { x=3; y=4; return x+y; }", 7)
        assertFns("int x, y; int main() { x=3; y=4; return x+y; }", 7)
        assertFns("int x[4]; int main() { x[0]=0; x[1]=1; x[2]=2; x[3]=3; return x[0]; }", 0)
        assertFns("int x[4]; int main() { x[0]=0; x[1]=1; x[2]=2; x[3]=3; return x[1]; }", 1)
        assertFns("int x[4]; int main() { x[0]=0; x[1]=1; x[2]=2; x[3]=3; return x[2]; }", 2)
        assertFns("int x[4]; int main() { x[0]=0; x[1]=1; x[2]=2; x[3]=3; return x[3]; }", 3)

        assertFns("int x; int main() { return sizeof(x); }", 4)
        assertFns("int x[4]; int main() { return sizeof(x); }", 16)
    }
}
