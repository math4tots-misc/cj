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
                "Tree.cat(Tree.cat(Tree.cat(Tree.char('a'), " +
                "Tree.char('b')), Tree.char('|')), Tree.char('c'))")
        }
        {
            val tree = parseTree("a(b|c)")
            Assert.equal(
                tree.repr(),
                "Tree.cat(Tree.char('a'), Tree.cat(Tree.cat(Tree.char('b'), Tree.char('|')), " +
                "Tree.char('c')))")
        }
    }

    def parseTree(pattern: String): Regex.Tree = Regex.PatternParser(pattern).parsePattern()
}
