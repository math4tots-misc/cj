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
        {
            val tree = parseTree("xy{3,5}")
            Assert.equal(
                tree.repr(),
                "Tree.cat(Tree.char('x'), Tree.interval(Tree.char('y'), 3, 5))")
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
        {
            val re = Regex("xy{3,5}")
            Assert.that(re.match("xy").isEmpty())
            Assert.that(re.match("xyy").isEmpty())
            Assert.equal(re.match("xyyy").get().matchText, "xyyy")
            Assert.that(re.matches("xyyy"))
            Assert.equal(re.match("xyyyy").get().matchText, "xyyyy")
            Assert.that(re.matches("xyyyy"))
            Assert.equal(re.match("xyyyyy").get().matchText, "xyyyyy")
            Assert.that(re.matches("xyyyyy"))
            Assert.equal(re.match("xyyyyyy").get().matchText, "xyyyyy")
            Assert.that(not re.matches("xyyyyyy"))
            Assert.equal(re.match("xyyyyyyy").get().matchText, "xyyyyy")
            Assert.that(not re.matches("xyyyyyyy"))
        }
        {
            val re = Regex("xy{3}")
            Assert.that(re.match("xy").isEmpty())
            Assert.that(not re.matches("xy"))
            Assert.that(re.match("xyy").isEmpty())
            Assert.that(not re.matches("xyy"))
            Assert.equal(re.match("xyyy").get().matchText, "xyyy")
            Assert.that(re.matches("xyyy"))
            Assert.equal(re.match("xyyyy").get().matchText, "xyyy")
            Assert.that(not re.matches("xyyyy"))
            Assert.equal(re.match("xyyyyy").get().matchText, "xyyy")
            Assert.that(not re.matches("xyyyyy"))
            Assert.equal(re.match("xyyyyyy").get().matchText, "xyyy")
            Assert.that(not re.matches("xyyyyyy"))
            Assert.equal(re.match("xyyyyyyy").get().matchText, "xyyy")
            Assert.that(not re.matches("xyyyyyyy"))
        }
        {
            val re = Regex("t\\+\\+")
            Assert.that(not re.matches("t+"))
            Assert.that(re.matches("t++"))
            Assert.that(not re.matches("t+++"))
        }
        {
            val re = Regex("[a-y][A-Z]+")
            Assert.that(re.matches("aYYYC"))
            Assert.that(re.matches("aY"))
            Assert.that(not re.matches("a"))
            Assert.that(not re.matches("zJJ"))
            Assert.that(re.matches("xJJ"))
            Assert.that(re.matches("bABCDE"))
        }
        {
            val re = Regex("[a-z]+")
            Assert.that(re.matches("ccc"))
            Assert.that(re.matches("zzz"))
        }
        {
            val re = Regex("[c-z]+")
            Assert.that(re.matches("ccc"))
            Assert.that(re.matches("zzz"))
            Assert.that(re.matches("yy"))
            Assert.that(re.matches("cczzyy"))
        }
    }

    @test
    def matcher() {
        {
            val re = Regex("a+", "b+", "ab+", "[c-z]+", "\n")
            val m = re.matcher("aaaxabbbazz\nasdf")
            val results : List[String] = []
            while not m.eof() {
                val mr = m.match().get()
                results.add(mr.toString())
                IO.println(mr)
            }
            Assert.equal(results, [
                "MatchResult(\"aaa\", 0, 1, 1)",
                "MatchResult(\"x\", 3, 1, 4)",
                "MatchResult(\"abbb\", 2, 1, 5)",
                "MatchResult(\"a\", 0, 1, 9)",
                "MatchResult(\"zz\", 3, 1, 10)",
                "MatchResult(\"\\n\", 4, 1, 12)",
                "MatchResult(\"a\", 0, 2, 1)",
                "MatchResult(\"sdf\", 3, 2, 2)",
            ])
        }
    }
}
