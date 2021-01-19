package cjx.re

import cjx.re.Regex

class RegexTest {
    @test
    def parseTreeSample() = {
        {
            val tree = parseTree("ab")
            Assert.equal(tree.repr(), "Tree.cat(Tree.char('a'), Tree.char('b'))")
        }
        {
            val tree = parseTree("ab|c")
            Assert.equal(
                tree.repr(),
                "Tree.alt(Tree.cat(Tree.char('a'), Tree.char('b')), Tree.char('c'))")
        }
        {
            val tree = parseTree("a(b|c)")
            Assert.equal(
                tree.repr(),
                "Tree.cat(Tree.char('a'), Tree.alt(Tree.char('b'), Tree.char('c')))")
        }
    }

    def parseTree(pattern: String): Regex.Tree = Regex.PatternParser(pattern).parsePattern()

    @test
    def samplePatterns() = {
        {
            val re = Regex("ab")
            Assert.equal(re.match("ab").get().matchIndex, 0)
            Assert.equal(re.match("ab").get().matchText, "ab")
            Assert.that(re.match("a").isEmpty())
            Assert.that(re.match("c").isEmpty())
        }
        {
            val re = Regex("ab|c")
            Assert.equal(re.match("ab").get().matchIndex, 0)
            Assert.equal(re.match("ab").get().matchText, "ab")
            Assert.equal(re.match("c").get().matchIndex, 0)
            Assert.equal(re.match("c").get().matchText, "c")
        }
        {
            val re = Regex("xy+")
            Assert.equal(re.match("xy").get().matchText, "xy")
            Assert.that(re.match("xxyy").isEmpty())
            Assert.that(re.match("x").isEmpty())
            Assert.equal(re.match("xyy").get().matchText, "xyy")
            Assert.equal(re.match("xyyyy").get().matchText, "xyyyy")
            Assert.equal(re.match("xyyyy444").get().matchText, "xyyyy")
            Assert.that(re.match("c").isEmpty())
        }
        {
            val re = Regex("xy*")
            Assert.equal(re.match("xy").get().matchText, "xy")
            Assert.equal(re.match("xxyy").get().matchText, "x")
            Assert.equal(re.match("x").get().matchText, "x")
            Assert.equal(re.match("xyy").get().matchText, "xyy")
            Assert.equal(re.match("xyyyy").get().matchText, "xyyyy")
            Assert.that(re.match("c").isEmpty())
        }
    }
}
