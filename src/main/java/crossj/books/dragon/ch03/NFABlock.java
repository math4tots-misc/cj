package crossj.books.dragon.ch03;

final class NFABlock {
    int startState;
    int acceptState;

    NFABlock(int startState, int acceptState) {
        this.startState = startState;
        this.acceptState = acceptState;
    }
}
