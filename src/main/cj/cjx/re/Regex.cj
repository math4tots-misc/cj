package cjx.re

import cj.StringBuilder
import cj.Error

class Regex {

    val nfa: NFA

    @variadic
    def new(patterns: List[String]): Self = Self.fromPatterns(patterns)

    def fromPatterns(patterns: List[String]): Self = Self.__malloc(NFA.fromPatterns(patterns))

    def match(self: Self, string: String): Nullable[MatchResult] = (
        self.matchEx(string, 0, string.size(), false))

    def matchFrom(self: Self, string: String, start: Int): Nullable[MatchResult] = (
        self.matchEx(string, start, string.size(), false))

    def fullMatch(self: Self, string: String): Nullable[MatchResult] = (
        self.matchEx(string, 0, string.size(), true))

    def matches(self: Self, string: String): Bool = self.fullMatch(string).isPresent()

    private def matchEx(
            self: Self,
            string: String,
            start: Int,
            end: Int,
            fullMatch: Bool): Nullable[MatchResult] = {
        val nfa = self.nfa
        var states = nfa.newStart()
        val patternCount = nfa.patternCount
        var i = start
        var lastMatchEnd = -1
        var lastMatchPatternIndex = -1
        while i < end and states {
            if not fullMatch {
                val rep = states.min()
                if rep < patternCount {
                    lastMatchEnd = i
                    lastMatchPatternIndex = rep
                }
            }
            val ch = string.charAt(i)
            states = nfa.transition(states, ch.toInt())
            i += ch.size()
        }
        if states {
            val rep = states.min()
            if rep < patternCount {
                lastMatchEnd = i
                lastMatchPatternIndex = rep
            }
        }
        if lastMatchEnd == -1 { null } else {
            null(MatchResult.__malloc(string, start, lastMatchEnd, lastMatchPatternIndex))
        }
    }

    class NFA {
        static val epsilon: Int = Graph.epsilon

        ## Number of patterns in this compiled Regex
        ##
        ## State patternCount is the start state,
        ## states 0..(patternCount - 1) are the accept states.
        val patternCount: Int

        ## Graph describing transitions
        val transitionMap: List[Map[Int, Set[Int]]]

        def fromTrees(trees: List[Tree]): Self = {
            val graph = Graph()
            for i = 0; i < trees.size(); i += 1 {
                Assert.equal(graph.newNode(), i)
            }
            val startState = graph.newNode()
            Assert.equal(startState, trees.size())
            for i = 0; i < trees.size(); i += 1 {
                val tree = trees[i]
                graph.buildBlock(tree, startState, i)
            }
            Self.__malloc(trees.size(), graph.transitionMap)
        }

        def fromPatterns(patterns: List[String]): Self = (
            Self.fromTrees(patterns.map(pattern -> PatternParser(pattern).parsePattern())))

        def newStart(self: Self): Set[Int] = self.closure(Set(self.patternCount))

        def transition(self: Self, states: Set[Int], ch: Int): Set[Int] = {
            val map = self.transitionMap
            self.closure(states.flatMap(state -> map[state].getOrElse(ch, () -> Set())))
        }

        def closure(self: Self, set: Set[Int]): Set[Int] = {
            val ret = Set[Int].empty()
            val empty = Set[Int].empty()
            val map = self.transitionMap
            val epsilon = Self.epsilon
            for state in set {
                ret.add(state)
                ret.addAll(map[state].getOrDefault(epsilon, empty))
            }
            ret
        }

        def dump(self: Self): String = {
            val sb = StringBuilder()
            sb.add("NFA (start = " + self.patternCount + ")\n")
            for i = 0; i < self.transitionMap.size(); i += 1 {
                sb.add("  " + i + ":\n")
                for edge in self.transitionMap[i].keys() {
                    sb.add("    ")
                    if edge == -2 {
                        sb.add("epsilon")
                    } else {
                        sb.add(edge.toChar().toString())
                    }
                    sb.add(" -> " + self.transitionMap[i][edge] + "\n")
                }
            }
            sb.toString()
        }
    }

    class MatchResult {
        val originalString: String

        ## Index from which the match starts
        val start: Int

        ## Index at which this match ends
        val end: Int

        ## The matching pattern index
        val matchIndex: Int

        def __get_matchText(self: Self): String = self.originalString[self.start:self.end]
    }

    ## NFA graph along the lines of Thompson's construction
    private class Graph {
        static val epsilon: Int = -2

        ## Transition map
        ## maps (node) -> (char-or-edge) -> (new-nodes)
        val transitionMap: List[Map[Int, Set[Int]]]

        def new(): Self = Self.__malloc([])

        def newNode(self: Self): Int = {
            val node = self.transitionMap.size()
            self.transitionMap.add(Map())
            node
        }

        def connect(self: Self, a: Int, ch: Int, b: Int) = {
            self.transitionMap[a].getOrInsert(ch, () -> Set()).add(b)
        }

        def buildBlock(self: Self, tree: Tree, var start: Int, var end: Int): Block = {
            start = if start == -1 { self.newNode() } else { start }
            end = if end == -1 { self.newNode() } else { end }
            union tree {
                case char(c) = {
                    self.connect(start, c.toInt(), end)
                }
                case cat(left, right) = {
                    val leftBlock = self.buildBlock(left, start, -1)
                    self.buildBlock(right, leftBlock.end, end)
                }
                case alt(left, right) = {
                    val leftBlock = self.buildBlock(left, -1, -1)
                    val rightBlock = self.buildBlock(right, -1, -1)
                    self.connect(start, Self.epsilon, leftBlock.start)
                    self.connect(start, Self.epsilon, rightBlock.start)
                    self.connect(leftBlock.end, Self.epsilon, end)
                    self.connect(rightBlock.end, Self.epsilon, end)
                }
                case star(inner) = self.buildIntervalBlock(start, end, inner, 0, -1)
                case plus(inner) = self.buildIntervalBlock(start, end, inner, 1, -1)
                case optional(inner) = self.buildIntervalBlock(start, end, inner, 0, 1)
                case interval(inner, min, max) = self.buildIntervalBlock(start, end, inner, min, max)
            }
            Block(start, end)
        }

        private def buildIntervalBlock(
                self: Self, var start: Int, end: Int, inner: Tree, min: Int, max: Int) = {
            val epsilon = Self.epsilon
            switch max {
                case -1 = {
                    if min == 0 {
                        # case 1: max is infinite and min = 0
                        # i.e. kleene star
                        self.buildBlock(inner, start, end)
                        self.connect(start, epsilon, end)
                        self.connect(end, epsilon, start)
                    } else {
                        # case 2: max is infinite and max > 0
                        # we build min blocks, with the last one using the overall end state.
                        # when min = 1, this is '+'
                        for i = 0; i + 1 < min; i += 1 {
                            start = self.buildBlock(inner, start, -1).start
                        }
                        self.buildBlock(inner, start, end)
                        self.connect(end, epsilon, start)
                    }
                }
                case 0 = {
                    # case 3: max = 0
                    self.connect(start, epsilon, end)
                }
                default = {
                    # case 4: 0 < max < infinity
                    # when min = 0 and max = 1, this is '?'
                    for i = 0; i < max; i += 1 {
                        if i >= min {
                            self.connect(start, epsilon, end)
                        }
                        start = self.buildBlock(inner, start, if i + 1 == max { end } else { -1 }).end
                    }
                }
            }
        }
    }

    @derive(pod)
    class Block {
        val start: Int
        val end: Int
    }

    @derive(repr)
    private union Tree {
        case char(Char)
        case cat(Tree, Tree)
        case alt(Tree, Tree)
        case star(Tree)
        case plus(Tree)
        case optional(Tree)
        case interval(Tree, Int, Int)
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
            var tree = self.parsePostfix()
            var repeat = true
            while repeat {
                switch self.peek() {
                    case '|'
                    case ')'
                    case '\0' = {
                        repeat = false
                    }
                    default = {
                        val rhs = self.parsePostfix()
                        tree = Tree.cat(tree, rhs)
                    }
                }
            }
            tree
        }

        def parsePostfix(self: Self): Tree = {
            val inner = self.parseAtom()
            switch self.peek() {
                case '*' = { self.next() ; Tree.star(inner) }
                case '+' = { self.next() ; Tree.plus(inner) }
                case '?' = { self.next() ; Tree.optional(inner) }
                case '{' = {
                    self.next()
                    val min = if self.at(',') { 0 } else { self.parseInt() }
                    val max = if self.consume(',') {
                        if self.at('}') { -1 } else { self.parseInt() }
                    } else {
                        min
                    }
                    self.expect('}')
                    Tree.interval(inner, min, max)
                }
                default = inner
            }
        }

        def parseInt(self: Self): Int = {
            val start = self.i
            while self.peek().isDigit() {
                self.next()
            }
            self.pattern[start:self.i].parseInt().get()
        }

        def parseAtom(self: Self): Tree = {
            switch self.peek() {
                case '\0' = throw self.err("unexpected end of string")
                case '\\' = {
                    self.next()
                    val ch = self.next()
                    switch ch {
                        case '?' = Tree.char('?')
                        case '|' = Tree.char('|')
                        case '[' = Tree.char('[')
                        case ']' = Tree.char(']')
                        case '(' = Tree.char('(')
                        case ')' = Tree.char(')')
                        case '.' = Tree.char('.')
                        case '\n' = Tree.char('\n')
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
                case '?'
                case '|'
                case ']'
                case ')' = throw self.err("Misplaced operator: " + self.peek())
                default = Tree.char(self.next())
            }
        }
    }
}
