package cj

class Test15BigInt {
    @test
    def sample() {
        {
            val x = 15n
            Assert.equal(x, x)
            Assert.equal(x, 15n)
            Assert.equal(x, 3n + 12n)
            Assert.that(x != 14n)
        }
    }

    @test
    def repr() {
        val x = -42n
        Assert.equal(x.toString(), "-42")
        Assert.equal(x.repr(), "-42n")
        val y = 9876n
        Assert.equal(y.toString(), "9876")
        Assert.equal(y.repr(), "9876n")
    }

    @test
    def largeValues() {
        {
            val x = 10n.ipow(50)
            Assert.equal(x.toString(), "1" + "0" * 50)
        }
    }

    @test
    def gcd() {
        # The same tests as in Tes02Numbers
        Assert.equal(BigInt.gcd(2n, 5n), 1n)
        Assert.equal(BigInt.gcd(14n, 21n), 7n)

        # negative numbers
        Assert.equal(BigInt.gcd(-14n, 42n), 14n)
        Assert.equal(BigInt.gcd(14n, -42n), 14n)
        Assert.equal(BigInt.gcd(-14n, -42n), 14n)

        # misc sample cases from the internet
        # https://users-cs.au.dk/chili/PBI04/ExamplePrograms/gcd_function_test.py
        {
            Assert.equal(BigInt.gcd(13n, 13n), 13n)
            Assert.equal(BigInt.gcd(37n, 600n), 1n)
            Assert.equal(BigInt.gcd(20n, 100n), 20n)
            Assert.equal(BigInt.gcd(100n, 20n), 20n)
            Assert.equal(BigInt.gcd(624129n, 2061517n), 18913n)
        }
    }

    @test
    def hash() {
        val set = SetOf(12n, 1n, 2n, -5n)
        Assert.equal(set.sorted(), [-5n, 1n, 2n, 12n])
    }
}
