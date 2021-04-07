package cjx.parser

## Some common boilerplate helper methods for implementing parsers
trait ParserMixin[Token] {
    def typeOfToken(token: Token): Int
    def nameOfType(type: Int): String

    def __get_tokens(self): List[Token]
    def __get_i(self): Int
    def __set_i(self, value: Int)

    def errorAt(self, message: String, token: Token): NoReturn
    def error(self, message: String): NoReturn = errorAt(message, peek())
    def errorType(self, type: Int): NoReturn = errorKind(nameOfType(type))
    def errorKind(self, kind: String): NoReturn = error(
        "Expected " + kind + " but got " + nameOfType(typeOfToken(peek())))

    def peek(self): Token { Assert(i < tokens.size()); tokens[i] }
    def next(self): Token { val tok = peek(); i++; tok }
    def at(self, type: Int): Bool = type == typeOfToken(peek())
    def atOffset(self, type: Int, offset: Int): Bool = (
        i + offset < tokens.size() and typeOfToken(tokens[i + offset]) == type)
    def assert(self, type: Int) { if not at(type) { errorType(type) } }
    def consume(self, type: Int): Bool = if at(type) { next(); true } else { false }
    def expect(self, type: Int): Token = { assert(type); next() }

    def parseJoin[T](self, open: Int, close: Int, sep: Int, el: Fn[T]): List[T] {
        expect(open)
        val list: List[T] = []
        while not consume(close) {
            list.add(el.call())
            if not consume(sep) {
                assert(close)
            }
        }
        list
    }
    def parseJoinOpt[T](self, open: Int, close: Int, sep: Int, el: Fn[T]): List[T] {
        if at(open) { parseJoin(open, close, sep, el) } else { [] }
    }

    ## Skip either a single token, or a single '{..}', '(..)', '[..]' blob.
    def skipOneBlob(self) {
        val startToken = peek()
        val type = typeOfToken(startToken)
        switch type {
            case '{'; case '('; case '[' {
                val close = switch type {
                    case '{' = '}'
                    case '(' = ')'
                    case '[' = ']'
                }
                next()
                var depth = 1
                while depth > 0 and i < tokens.size() {
                    switch typeOfToken(peek()) {
                        case '{'; case '('; case '[' { depth++ }
                        case '}'; case ')'; case ']' { depth-- }
                        else = ()
                    }
                    next()
                }
                if i >= tokens.size() {
                    errorAt("Mismatched grouping symbol", startToken)
                }
            }
            case '}'; case')'; case ']' {
                error("Unexpected close grouping token")
            }
            else = next()
        }
    }
}
