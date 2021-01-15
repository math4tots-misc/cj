package cj

class Test07String {
    @test
    def charAndInt() = {
        {
            val i : Int = 'H'
            Assert.equal(i, 72)
            Assert.equal(65, 'A')
            Assert.equal(97, 'a')
        }
        Assert.equal('Z'.toInt(), 90)
        Assert.equal((90).toChar(), 'Z')
    }

    @test
    def unicode() = {
        {
            val s = "한글"
            Assert.equal(s.size(), '한'.size() + '글'.size())
            Assert.equal(s.charAt(0), '한')
            Assert.equal(s.charAt(0).toInt(), 0xD55C)
            Assert.equal(s.charAt('한'.size()).toInt(), 0xAE00)
        }
    }

    @test
    def nonBMP() = {
        Assert.that('👌'.size() > 1)
        {
            val s = "hello😊world"
            Assert.that(s.size() > "hello world".size())
            var i = 0
            var chars = List[Char].empty()
            while i < s.size() {
                val ch = s.charAt(i)
                chars.add(ch)
                i += ch.size()
            }
            Assert.equal(chars, [
                'h', 'e', 'l', 'l', 'o', '😊', 'w', 'o', 'r', 'l', 'd'
            ])
            Assert.equal(chars, s.iter().toList())
        }
    }
}
