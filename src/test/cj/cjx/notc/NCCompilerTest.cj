package cjx.notc

import cjx.notc.NCCompiler

class NCCompilerTest {

    def assertCode(source: String, code: Int) {
        Assert.equal(NCCompiler.compileAndRunMain(source), code)
    }

    @test
    def sample() {
        assertCode("int main() = 0", 0)
        assertCode("int main() = 24", 24)
        assertCode("int main() = 5 + 7", 12)
        assertCode("int main() = 5 - 7", -2)
        assertCode("int main() = 5+20-4", 21)
        assertCode("int main() = 12 + 34 - 5", 41)

        assertCode("int main() = 5+6*7", 47)
        assertCode("int main() = 5*(9-6)", 15)
        assertCode("int main() = (3+5)/2", 4)

        assertCode("int main() = -10+20", 10)
        assertCode("int main() = - -10", 10)
        assertCode("int main() = - - +10", 10)

        assertCode("int main() = 0==1", 0)
        assertCode("int main() = 42==42", 1)
        assertCode("int main() = 0!=1", 1)
        assertCode("int main() = 42!=42", 0)

        assertCode("int main() = 0<1", 1)
        assertCode("int main() = 1<1", 0)
        assertCode("int main() = 2<1", 0)
        assertCode("int main() = 0<=1", 1)
        assertCode("int main() = 1<=1", 1)
        assertCode("int main() = 2<=1", 0)

        assertCode("int main() = 1>0", 1)
        assertCode("int main() = 1>1", 0)
        assertCode("int main() = 1>2", 0)
        assertCode("int main() = 1>=0", 1)
        assertCode("int main() = 1>=1", 1)
        assertCode("int main() = 1>=2", 0)

        assertCode("int main() = { 1; 2; 3; }", 3)

        assertCode("int main() = { return 1; 2; 3; }", 1)
        assertCode("int main() = { 1; 2; return 3; }", 3)
        assertCode("int main() = { 1; {2;} return 3; }", 3)

        assertCode("int main() = { int a = 3; a; }", 3)
        assertCode("int main() = { int a = 3; int z = 5; a + z; }", 8)
        assertCode("int main() = { int a = 3, z = 5; a + z; }", 8)
        assertCode("int main() = { int b; int a=b=3; a+b; }", 6)
        assertCode("int main() = { int a, b; a=b=3; a+b; }", 6)
    }

}
