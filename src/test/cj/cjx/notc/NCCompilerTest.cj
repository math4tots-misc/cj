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
    }

}
