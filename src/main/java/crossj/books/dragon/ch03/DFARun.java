package crossj.books.dragon.ch03;

final class DFARun {
    private final DFA dfa;
    private int state;

    DFARun(DFA dfa) {
        this.dfa = dfa;
        this.state = dfa.getStartState();
    }

    /**
     * Returns true if we are currently in an accepting state
     */
    public boolean isMatching() {
        return dfa.getMatchIndex(state) >= 0;
    }

    /**
     * If isMatching is true, returns the index of the first matching RegexNode.
     * Otherwise, returns -1
     */
    public int getMatchingAlternative() {
        return dfa.getMatchIndex(state);
    }

    /**
     * Returns true if it's no longer possible to enter the accepting state.
     */
    public boolean isDead() {
        return dfa.isDeadState(state);
    }

    public void accept(int letter) {
        state = dfa.transition(state, letter);
    }
}
