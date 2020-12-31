package crossj.books.dragon.ch03;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;
import crossj.base.Repr;
import crossj.base.Set;
import crossj.base.Str;
import crossj.base.Try;
import crossj.base.XIterable;

final class NFA {
    public static NFA fromRegexNodeList(List<RegexNode> nodes) {
        return NFABuilder.buildFromRegexNodeList(nodes);
    }

    public static NFA fromRegexNodes(RegexNode... nodes) {
        return fromRegexNodeList(List.fromJavaArray(nodes));
    }

    public static Try<NFA> fromPatternList(List<String> patterns) {
        var nodes = List.<RegexNode>of();
        for (var pattern : patterns) {
            var tryNode = RegexNode.fromPattern(pattern);
            if (tryNode.isFail()) {
                return tryNode.castFail();
            }
            nodes.add(tryNode.get());
        }
        return Try.ok(fromRegexNodeList(nodes));
    }

    public static Try<NFA> fromPatterns(String... patterns) {
        return fromPatternList(List.fromJavaArray(patterns));
    }

    private final List<Map<Optional<Integer>, Set<Integer>>> transitionMap;
    private final int acceptState;

    NFA(List<Map<Optional<Integer>, Set<Integer>>> transitionMap, int acceptState) {
        this.transitionMap = transitionMap;
        this.acceptState = acceptState;
    }

    public int getStartState() {
        return acceptState + 1;
    }

    public int getAcceptState() {
        return acceptState;
    }

    public int getNumberOfAlternatives() {
        return acceptState;
    }

    /**
     * Given a set of states, returns the epsilon-closure of those states.
     */
    public Set<Integer> epsilonClosureOf(Set<Integer> states) {
        var todo = List.fromIterable(states);
        var closure = Set.fromIterable(states);
        while (todo.size() > 0) {
            var state = todo.pop();
            for (var neighborState : transitionMap.get(state).getOrElse(Optional.empty(), () -> Set.of())) {
                if (!closure.contains(neighborState)) {
                    closure.add(neighborState);
                    todo.add(neighborState);
                }
            }
        }
        return closure;
    }

    /**
     * Given a set of states and an input letter, returns a new set of states after
     * the given letter is accepted.
     *
     * The returned set accounts for an epsilon closure after the transition.
     */
    public Set<Integer> transitionOf(XIterable<Integer> states, int letter) {
        if (letter < 0 || letter >= Alphabet.COUNT) {
            letter = Alphabet.CATCH_ALL;
        }
        var transition = Optional.of(letter);
        return epsilonClosureOf(Set.fromIterable(
                states.iter().flatMap(state -> transitionMap.get(state).getOrElse(transition, () -> Set.of()))));
    }

    /**
     * Given a set of states, returns a set of letters that appears as an edge
     * coming out from at least one of those states.
     */
    Set<Integer> lettersFromStates(XIterable<Integer> states) {
        var letters = Set.<Integer>of();
        for (var state : states) {
            for (var transition : transitionMap.get(state).keys()) {
                if (transition.isPresent()) {
                    letters.add(transition.get());
                }
            }
        }
        return letters;
    }

    public NFARun start() {
        return new NFARun(this);
    }

    public String inspect() {
        var sb = Str.builder();
        sb.s("=== NFA TRANSITIONS === (start = ").i(getStartState()).s(", accept = ").i(acceptState).s(")\n");
        for (int state = 0; state < transitionMap.size(); state++) {
            sb.s("  ").i(state);
            if (state < acceptState) {
                sb.s(" <accept ").i(state).s(">");
            } else if (state == acceptState) {
                sb.s(" <universal accept>");
            } else if (state == getStartState()) {
                sb.s(" <START>");
            }
            sb.s("\n");
            var localMap = transitionMap.get(state);

            if (localMap.containsKey(Optional.empty())) {
                sb.s("    epsilon -> ").obj(List.sorted(localMap.get(Optional.empty()))).s("\n");
            }
            for (int key = 0; key < Alphabet.COUNT; key++) {
                var newStates = localMap.getOrNull(Optional.of(key));
                if (newStates == null) {
                    continue;
                }
                int end = key + 1;
                while (end < Alphabet.COUNT && localMap.getOptional(Optional.of(end)).equals(Optional.of(newStates))) {
                    end++;
                }
                sb.s("    ").s(reprchar(key));
                if (key + 1 < end) {
                    // there are consecutive runs of keys that lead to the same states
                    sb.s("-").s(reprchar(end - 1));
                    key = end - 1;
                }
                sb.s(" -> ").obj(List.sorted(newStates)).s("\n");
            }
        }
        return sb.build();
    }

    private String reprchar(int c) {
        switch (c) {
            case '\'': return "'\\''";
            case '"': return "'\"'";
            default: return Repr.reprchar(c).replace("\"", "'");
        }
    }

    /**
     * Tries to find the longest matching substring that starts from the beginning
     * of the given string.
     *
     * Returns the length of the match if found, or returns -1 if there is no match.
     */
    public int match(String text) {
        int lastMatch = -1;
        int pos = 0;
        var run = new NFARun(this);
        if (run.isMatching()) {
            lastMatch = pos;
        }
        while (!run.isDead() && pos < text.length()) {
            var letter = text.charAt(pos);
            run.accept(letter);
            pos++;
            if (run.isMatching()) {
                lastMatch = pos;
            }
        }
        return lastMatch;
    }
}
