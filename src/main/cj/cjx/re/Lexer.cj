package cjx.re

import cj.Error
import cjx.re.Regex

class Lexer[Token] {
    val regex: Regex
    val callbacks: List[Fn[Regex.MatchResult, List[Token]]]
    val onError: Fn[Regex.Matcher, Unit]
    var onEOF: Fn[Regex.Matcher, List[Token]]

    class Builder[Token] {
        val patterns: List[String] = []
        val callbacks: List[Fn[Regex.MatchResult, List[Token]]] = []
        var onError: Fn[Regex.Matcher, Unit] = m -> throw Error("Unrecognized token")
        var onEOF: Fn[Regex.Matcher, List[Token]] = m -> []

        def add(self, pattern: String, callback: Fn[Regex.MatchResult, List[Token]]) {
            patterns.add(pattern)
            callbacks.add(callback)
        }

        def onError(self, f: Fn[Regex.Matcher, Unit]) {
            self.onError = f
        }

        ## On EOF
        def onEOF(self, f: Fn[Regex.Matcher, List[Token]]) {
            self.onEOF = f
        }

        def build(self): Lexer[Token] = (
            Lexer[Token].__malloc(Regex.fromPatterns(patterns), callbacks, onError, onEOF))
    }

    def builder(): Builder[Token] = Builder[Token].__malloc()

    def lex(self, filename: String, string: String): List[Token] = {
        val matcher = regex.matcherWithFilename(filename, string)
        val tokens: List[Token] = []
        var ok = true
        while ok and not matcher.eof() {
            if null(matchResult) = matcher.match() {
                tokens.addAll(callbacks[matchResult.matchIndex].call(matchResult))
            } else {
                onError.call(matcher)
                ok = false
            }
        }
        tokens.addAll(onEOF.call(matcher))
        tokens
    }
}
