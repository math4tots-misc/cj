package crossj.books.dragon.ch03;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;
import crossj.base.Set;

final class NFABuilder {

    static NFA buildFromRegexNode(RegexNode node) {
        return buildFromRegexNodeList(List.of(node));
    }

    static NFA buildFromRegexNodeList(List<RegexNode> nodes) {
        var builder = new NFABuilder();

        // The first nodes.size() states are all accepting states,
        // each corresponding to the accepting state of the corresponding RegexNode.
        // The state 'nodes.size()' is the universal accepting state (i.e. all other accepting
        // states have an epsilon transition into it),
        // and state 'nodes.size() + 1' is the start state.
        for (int i = 0; i < nodes.size(); i++) {
            Assert.equals(builder.newState(), i);
        }
        var joinAcceptState = builder.newState();
        var startState = builder.newState();

        for (int i = 0; i < nodes.size(); i++) {
            var node = nodes.get(i);
            var block = builder.buildBlock(node, -1, i);
            builder.connect(startState, Optional.empty(), block.startState);
            builder.connect(i, Optional.empty(), joinAcceptState);
        }

        Assert.equals(joinAcceptState + 1, startState);
        Assert.equals(joinAcceptState, nodes.size());
        return new NFA(builder.transitionMap, joinAcceptState);
    }

    private List<Map<Optional<Integer>, Set<Integer>>> transitionMap = List.of();

    private NFABuilder() {
    }

    private int newState() {
        int state = transitionMap.size();
        transitionMap.add(Map.of());
        return state;
    }

    void connect(int startState, Optional<Integer> label, int acceptState) {
        if (startState == acceptState && label.isEmpty()) {
            // there's always an epsilon transition from a state to itself, so
            // there's no need to explicitly create one.
            return;
        }

        var localTransitions = transitionMap.get(startState);
        if (!localTransitions.containsKey(label)) {
            if (label.isPresent()) {
                int letter = label.get();
                Assert.that(Alphabet.contains(letter));
            }
            localTransitions.put(label, Set.of());
        }
        localTransitions.get(label).add(acceptState);
    }

    // More or less as described in pages 159 - 161 for how to create a NFA
    // from a regex syntax tree.
    NFABlock buildBlock(RegexNode node, int startState, int acceptState) {
        if (startState == -1) {
            startState = newState();
        }
        if (acceptState == -1) {
            acceptState = newState();
        }
        node.buildBlock(this, startState, acceptState);
        return new NFABlock(startState, acceptState);
    }
}
