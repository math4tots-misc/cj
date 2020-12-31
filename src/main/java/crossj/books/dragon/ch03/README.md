A basic lexical analyzer generator based on content in chapter 3 of the dragon book.

The analyzer is basically only able to distinguish between ASCII types. All unicode
codepoints outside the ASCII range are mapped to `127`.

There are 5 public classes in this package:

* `Regex`
    A class that holds compiled regular expressions.
    There are convenience methods that allow for quickly checking that
    a string matches, but for the most flexibility, you'll want to use
    the `matcher()` method to create a `RegexMatcher` instance.

    A `Regex` can be built with multiple patterns, and when matching
    with `RegexMatcher`, you can detect which of the initial patterns
    actually matched the string.

    In general, the longest possible match is preferred, and in
    case of a tie, the first listed pattern will have preferences.

* `RegexMatcher`
    A class that holds
    1. a regular expression,
    2. a string to match against,
    3. and the current match status.
    After a successful match, the matcher object will hold
    additional information (e.g. the matched text, which `Regex`
    pattern matched)

* `Alphabet`
    Some metadata about the alphabet used in the matchers.

* `Lexer`
    A utility built on top of `Regex` for quickly implementing
    lexical analyzers.

    The basic usage involves providing pairs of patterns and callbacks
    where callbacks are called whenever the matching pattern is found.
    The callbacks return a `Try<List<Token>>` allowing them to control
    the error message returned as well as which and how many `Token`s
    are produced from the pattern.

* `LexerBuilder`
    Helper class for building `Lexer` instances.
