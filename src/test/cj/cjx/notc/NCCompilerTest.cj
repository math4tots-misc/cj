package cjx.notc

import cjx.notc.NCCompiler

class NCCompilerTest {
    private static val compiler: NCCompiler = NCCompiler()

    def assertCode(source: String, code: Int) {
        compiler.includePrelude = false
        Assert.equal(compiler.compileAndRunMain(source), code)
    }

    @test
    def sample1() {
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

        assertCode("int main() = { ;;; return 5; }", 5)

        assertCode("int main() = { if (0) return 2; return 3; }", 3)
        assertCode("int main() = { if (1-1) return 2; return 3; }", 3)
        assertCode("int main() = { if (1) return 2; return 3; }", 2)
        assertCode("int main() = { if (2-1) return 2; return 3; }", 2)
        assertCode("int main() = { if (0) { 1; 2; return 3; } else { return 4; } }", 4)
        assertCode("int main() = { if (1) { 1; 2; return 3; } else { return 4; } }", 3)

        assertCode("int main() { if (0) return 2; return 3; }", 3)
        assertCode("int main() { if (1-1) return 2; return 3; }", 3)
        assertCode("int main() { if (1) return 2; return 3; }", 2)
        assertCode("int main() { if (2-1) return 2; return 3; }", 2)
        assertCode("int main() { if (0) { 1; 2; return 3; } else { return 4; } }", 4)
        assertCode("int main() { if (1) { 1; 2; return 3; } else { return 4; } }", 3)
    }

    @test
    def samples2() {
        assertCode("int main() { if (1) { 1\n2\nreturn 3 } else { return 4 } }", 3)
        assertCode("int main() { int i=0; int j=0; for (i=0; i<=10; i=i+1) j=i+j; j}", 55)
        assertCode("int main() { for (;;) { return 3 } return 5 }", 3)
        assertCode("int main() { int i=0; while(i<10) { i=i+1; } return i; }", 10)
        assertCode("int foo() = 12321\nint main() = foo()", 12321)
        assertCode("int add2(int x) = x + 2\nint main() = add2(72)", 74)
        # assertCode("int main() { int[] arr = new!(int, 3); 0 }", 74)

        assertCode("int main() { memsize!() }", 1) # start out with 1 page of memory (64k)
        assertCode("int main() { load!(int, 5) }", 0) # memory should be fresh (zeroed out)
        assertCode("int main() { store!(int, 4, 600); load!(int, 5) }", 600 // 256)
        assertCode("int main() { store!(int, 4, 600); load!(int, 4) }", 600)
    }

}
