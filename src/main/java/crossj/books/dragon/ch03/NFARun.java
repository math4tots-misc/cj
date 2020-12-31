package crossj.books.dragon.ch03;

import crossj.base.Set;

/**
 * A running instance of an NFA
 */
final class NFARun {
    private final NFA nfa;
    private Set<Integer> currentStates;

    NFARun(NFA nfa) {
        this.nfa = nfa;
        this.currentStates = nfa.epsilonClosureOf(Set.of(nfa.getStartState()));
    }

    /**
     * Returns true if we are currently in an accepting state
     */
    public boolean isMatching() {
        return currentStates.contains(nfa.getAcceptState());
    }

    /**
     * If isMatching is true, returns the index of the first matching RegexNode.
     * Otherwise, returns -1
     */
    public int getMatchingAlternative() {
        int n = nfa.getNumberOfAlternatives();
        for (int i = 0; i < n; i++) {
            if (currentStates.contains(i)) {
                return i;
            }
        }
        // No match was found
        return -1;
    }

    /**
     * Returns true if our set of states is currently empty, and it's
     * impossible to enter the accepting state.
     */
    public boolean isDead() {
        return currentStates.size() == 0;
    }

    /**
     * Updates the current state based on the next input letter.
     */
    public void accept(int letter) {
        currentStates = nfa.transitionOf(currentStates, letter);
    }
}
