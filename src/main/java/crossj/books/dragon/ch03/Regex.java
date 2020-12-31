package crossj.books.dragon.ch03;

import crossj.base.List;
import crossj.base.Try;

/**
 * A Regex is a compiled list of patterns.
 *
 * When a regex is matched, the result includes a match index that indicates
 * which of the patterns that make up the Regex matched.
 *
 * For example:
 *
 * <pre>
 * var re = Regex.fromPatterns("aa*", "bb*");
 * var matcher = re.matcher("bb");
 * Assert.that(matcher.match());
 * Assert.equals(matcher.getMatchIndex(), 1); // "bb*" was the pattern at index 1
 * </pre>
 */
public final class Regex {
    private final DFA dfa;

    private Regex(DFA dfa) {
        this.dfa = dfa;
    }

    public static Regex fromIntArray(int[] arr) {
        return new Regex(DFA.fromIntArray(arr));
    }

    public int[] toIntArray() {
        return dfa.toIntArray();
    }

    public static Try<Regex> fromPatternList(List<String> patterns) {
        var regexNodes = List.<RegexNode>of();
        for (var pattern : patterns) {
            var tryNode = RegexNode.fromPattern(pattern);
            if (tryNode.isFail()) {
                return tryNode.castFail();
            }
            regexNodes.add(tryNode.get());
        }
        var nfa = NFA.fromRegexNodeList(regexNodes);
        var dfa = DFA.fromNFA(nfa);
        return Try.ok(new Regex(dfa));
    }

    public static Try<Regex> fromPatterns(String... patterns) {
        return fromPatternList(List.fromJavaArray(patterns));
    }

    public RegexMatcher matcher(String string) {
        return new RegexMatcher(dfa, string);
    }

    DFA getDfa() {
        return dfa;
    }

    /**
     * Returns true if the entire string matches this regex.
     *
     * Equivalent to <code>re.matcher(string).matchAll()</code>
     */
    public boolean matches(String string) {
        return matcher(string).matchAll();
    }

    /**
     * For debugging purposes.
     *
     * Returns a string describing the underlying DFA.
     */
    public String inspect() {
        return dfa.inspect();
    }
}
