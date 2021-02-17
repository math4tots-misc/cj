package cj

class Test16When {

    union Sample {
        case foo(Int, Int, String)
        case bar(String, Double)
    }

    @test
    def dotdot() {
        {
            val x = Sample.foo(5, 7, "hi")
            {
                val (a, b) = when x {
                    case foo(s, r, ..) = (s, r)
                    case bar(..) = (-1, -2)
                }
                Assert.equal(a, 5)
                Assert.equal(b, 7)
            }
            {
                val (a, b) = when Sample.bar("asdf", 24) {
                    case foo(s, r, ..) = (s, r)
                    case bar(..) = (-1, -2)
                }
                Assert.equal(a, -1)
                Assert.equal(b, -2)
            }
        }
    }
}
