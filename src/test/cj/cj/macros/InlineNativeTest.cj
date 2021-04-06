package cj.macros

class InlineNativeTest {

    @test
    def inferredReturnType() {
        {
            val i: Int = js0!("5")
            Assert.equal(i, 5)
        }
    }
}
