package cjx.re

import cj.Error
import cjx.re.Regex

class Lexer[Token] {
    val regex: Regex
    val callbacks: List[Fn[Regex.MatchResult, List[Token]]]
    val onerr: Fn[Regex.Matcher, Unit]

    class Builder[Token] {
        val patterns: List[String] = []
        val callbacks: List[Fn[Regex.MatchResult, List[Token]]] = []
        var onerr: Fn[Regex.Matcher, Unit] = m -> throw Error("Unrecognized token")

        def add(self, pattern: String, callback: Fn[Regex.MatchResult, List[Token]]) {
            patterns.add(pattern)
            callbacks.add(callback)
        }

        def onerr(self, f: Fn[Regex.Matcher, Unit]) {
            self.onerr = f
        }

        def build(self): Lexer[Token] = (
            Lexer[Token].__malloc(Regex.fromPatterns(patterns), callbacks, onerr))
    }

    def builder(): Builder[Token] = Builder[Token].__malloc()

    def lex(self, string: String): List[Token] = {
        val matcher = regex.matcher(string)
        val tokens: List[Token] = []
        var ok = true
        while ok and not matcher.eof() {
            if null(matchResult) = matcher.match() {
                tokens.addAll(callbacks[matchResult.matchIndex].call(matchResult))
            } else {
                onerr.call(matcher)
                ok = false
            }
        }
        tokens
    }
}
