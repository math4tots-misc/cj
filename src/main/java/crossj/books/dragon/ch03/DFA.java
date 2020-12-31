package crossj.books.dragon.ch03;

import crossj.base.Assert;
import crossj.base.FrozenSet;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Repr;
import crossj.base.Set;
import crossj.base.Str;

final class DFA {
    private final int startState;
    private final int[] transitionMap;
    private final int[] acceptMap;

    DFA(int startState, int[] transitionMap, int[] acceptMap) {
        Assert.equals(transitionMap.length, acceptMap.length * Alphabet.COUNT);
        this.startState = startState;
        this.transitionMap = transitionMap;
        this.acceptMap = acceptMap;
    }

    public int[] toIntArray() {
        var ret = new int[acceptMap.length * (Alphabet.COUNT + 1) + 1];
        int i = 0;
        ret[i++] = startState;
        for (int j = 0; j < transitionMap.length; j++) {
            ret[i++] = transitionMap[j];
        }
        for (int j = 0; j < acceptMap.length; j++) {
            ret[i++] = acceptMap[j];
        }
        Assert.equals(i, ret.length);
        return RLE.encode(ret);
    }

    public static DFA fromIntArray(int[] arr) {
        arr = RLE.decode(arr);
        Assert.equals(arr.length % (Alphabet.COUNT + 1), 1);
        int stateCount = (arr.length - 1) / (Alphabet.COUNT + 1);
        int i = 0;
        int startState = arr[i++];
        var transitionMap = new int[stateCount * Alphabet.COUNT];
        for (int j = 0; j < transitionMap.length; j++) {
            transitionMap[j] = arr[i++];
        }
        var acceptMap = new int[stateCount];
        for (int j = 0; j < acceptMap.length; j++) {
            acceptMap[j] = arr[i++];
        }
        return new DFA(startState, transitionMap, acceptMap);
    }

    public int getNumberOfStates() {
        return acceptMap.length;
    }

    /**
     * Returns the start state of this DFA
     */
    public int getStartState() {
        return startState;
    }

    /**
     * Returns the index of the regex alternative that matches with the given state.
     * If the given state does not match any alternatives, returns -1.
     */
    public int getMatchIndex(int state) {
        return state < 0 ? -1 : acceptMap[state];
    }

    /**
     * Returns true if the given state is dead and it is no longer possible to reach
     * an accepting state.
     */
    public boolean isDeadState(int state) {
        return state < 0;
    }

    /**
     * Given the current state, and an input letter, returns the new resulting
     * state.
     */
    public int transition(int state, int letter) {
        if (state < 0) {
            return -1;
        }
        if (letter < 0 || letter >= Alphabet.COUNT) {
            letter = Alphabet.CATCH_ALL;
        }
        return transitionMap[state * Alphabet.COUNT + letter];
    }

    public DFARun start() {
        return new DFARun(this);
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
        var run = start();
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

    public String inspect() {
        var sb = Str.builder();
        sb.s("=== DFA TRANSITIONS === (start = ").i(getStartState()).s(")\n");

        for (int state = 0; state < acceptMap.length; state++) {
            sb.s("  ").i(state);
            if (state == startState) {
                sb.s(" [START]");
            }
            if (acceptMap[state] >= 0) {
                sb.s(" (accept ").i(acceptMap[state]).s(")");
            }
            sb.s("\n");
            for (int letter = 0; letter < Alphabet.COUNT; letter++) {
                int newState = transitionMap[state * Alphabet.COUNT + letter];
                if (newState >= 0) {
                    int end = letter;
                    while (end < Alphabet.COUNT && transitionMap[state * Alphabet.COUNT + end] == newState) {
                        end++;
                    }
                    int last = end - 1;
                    sb.s("    ");
                    if (letter < last) {
                        // Consecutive runs of characters transition to the same state
                        sb.s(Repr.reprchar(letter)).s("-").s(Repr.reprchar(last));
                        letter = last;
                    } else {
                        sb.s(Repr.reprchar(letter));
                    }
                    sb.s(" -> ").i(newState).s("\n");
                }
            }
        }

        return sb.build();
    }

    public static DFA fromRegexNodes(RegexNode... nodes) {
        return fromNFA(NFA.fromRegexNodeList(List.fromJavaArray(nodes)));
    }

    public static DFA fromNFA(NFA nfa) {
        var currentStates = nfa.epsilonClosureOf(Set.of(nfa.getStartState()));
        var startState = FrozenSet.fromIterable(currentStates);
        var transitionMap = Map.<FrozenSet<Integer>, Map<Integer, FrozenSet<Integer>>>of();
        var seen = Set.of(startState);
        var todo = List.of(startState);
        var allStates = List.<FrozenSet<Integer>>of();
        var acceptMap = Map.<FrozenSet<Integer>, Integer>of();

        while (todo.size() > 0) {
            var state = todo.pop();
            allStates.add(state);
            transitionMap.put(state, Map.of());
            var localMap = transitionMap.get(state);

            // Check if this is an accepting state, and if so, which alternative it matches.
            int acceptingAlternative = -1;
            for (int alt = 0; alt < nfa.getNumberOfAlternatives(); alt++) {
                if (state.contains(alt)) {
                    acceptingAlternative = alt;
                    break;
                }
            }
            if (acceptingAlternative != -1) {
                acceptMap.put(state, acceptingAlternative);
            }

            var letters = nfa.lettersFromStates(state);
            for (var letter : letters) {
                var newState = FrozenSet.fromIterable(nfa.transitionOf(state, letter));
                localMap.put(letter, newState);
                if (!seen.contains(newState)) {
                    seen.add(newState);
                    todo.add(newState);
                }
            }
        }

        var dfair = DFAIR.fromFrozenSetDescription(allStates, startState, transitionMap, acceptMap);
        return dfair.withMinimumNumberOfStates();
    }
}
