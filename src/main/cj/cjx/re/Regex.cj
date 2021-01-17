package cjx.re

import cj.Error

class Regex {

    ## NFA graph along the lines of Thompson's construction
    class Graph {
        ## Transition map
        ## maps (node) -> (char-or-edge) -> (new-node)
        val _transitionMap: List[Map[Int, Int]]

        ## Accept map
        ## maps (node) -> (matching-pattern-index)
        ## if the node is an accepting state
        val _acceptMap: Map[Int, Int]

        def new(): Self = Self.__malloc([], Map())

        def newNode(self: Self): Int = {
            val node = self._transitionMap.size()
            self._transitionMap.add(Map())
            node
        }

        def connect(self: Self, a: Int, ch: Int, b: Int) = {
            self._transitionMap[a][ch] = b
        }

        ## Mark the given node with the given accept index
        def accept(self: Self, node: Int, index: Int) = {
            self._acceptMap[node] = index
        }
    }

    @derive(repr)
    private union Tree {
        case char(Char)
        case cat(Tree, Tree)
        case alt(Tree, Tree)
    }

    private class PatternParser {
        private val pattern: String
        private var i: Int
        private val graph: Graph

        def new(pattern: String): Self = Self.__malloc(pattern, 0, Graph())

        def err(self: Self, message: String): Error = Error(message)

        def peek(self: Self): Char = (
            if self.i < self.pattern.size() { self.pattern.charAt(self.i) } else { '\0' })

        def next(self: Self): Char = {
            val ch = self.peek()
            self.i += 1
            ch
        }

        def at(self: Self, ch: Char): Bool = self.peek() == ch

        def consume(self: Self, ch: Char): Bool = {
            if self.at(ch) {
                self.next()
                true
            } else {
                false
            }
        }

        def expect(self: Self, ch: Char) = {
            if not self.consume(ch) {
                throw self.err("Expected " + ch.repr() + " but got " + self.peek().repr())
            }
        }

        def parsePattern(self: Self): Tree = self.parseOr()

        def parseOr(self: Self): Tree = {
            var tree = self.parseAnd()
            while self.consume('|') {
                val rhs = self.parseAnd()
                tree = Tree.alt(tree, rhs)
            }
            tree
        }

        def parseAnd(self: Self): Tree = {
            var tree = self.parseAtom()
            var repeat = true
            while repeat {
                switch self.peek() {
                    case '\0'
                    case ')' = {
                        repeat = false
                    }
                    default = {
                        val rhs = self.parseAtom()
                        tree = Tree.cat(tree, rhs)
                    }
                }
            }
            tree
        }

        def parseAtom(self: Self): Tree = {
            switch self.peek() {
                case '\0' = throw self.err("unexpected end of string")
                case '\\' = {
                    self.next()
                    val ch = self.next()
                    switch ch {
                        case '\\' = Tree.char('\\')
                        case '0' = Tree.char('\0')
                        default = throw self.err("Invalid escape char: " + ch)
                    }
                }
                case '(' = {
                    self.next()
                    val tree = self.parsePattern()
                    self.expect(')')
                    tree
                }
                default = Tree.char(self.next())
            }
        }
    }
}
