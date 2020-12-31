package crossj.books.dragon.ch03;

import crossj.base.Assert;
import crossj.base.FrozenSet;
import crossj.base.List;
import crossj.base.M;
import crossj.base.Map;

/**
 * Intemediate representation of a DFA.
 *
 * The main purpose of the DFAIR is to reduce the number of states in the DFA
 * before creating the optimized DFA representation. We do this because the
 * initial DFA generated from the NFA may have a fairly large number of states,
 * and the optimized DFA representation uses a fixed amount of memory for each
 * state regardless of how dense the DFA transition graph is.
 *
 * The DFAIR is equivalent to the DFA representation, but maintains a sparse
 * representation to better handle larger number of states.
 */
final class DFAIR {

    static DFAIR fromFrozenSetDescription(List<FrozenSet<Integer>> allStates, FrozenSet<Integer> startState,
            Map<FrozenSet<Integer>, Map<Integer, FrozenSet<Integer>>> transitionMap,
            Map<FrozenSet<Integer>, Integer> acceptMap) {

        // IO.println("allStates = " + allStates);
        // IO.println("startState = " + List.sorted(startState));
        // IO.println("transitionMap = " + transitionMap);
        // IO.println("acceptMap = " + acceptMap);

        // ensure that startState is always zero.
        for (int i = 0; i < allStates.size(); i++) {
            if (allStates.get(i).equals(startState)) {
                if (i != 0) {
                    allStates.swap(i, 0);
                }
                break;
            }
        }

        var frozenSetToIndex = Map.<FrozenSet<Integer>, Integer>of();
        for (int i = 0; i < allStates.size(); i++) {
            frozenSetToIndex.put(allStates.get(i), i);
        }

        // determine newTransitionMap
        Map<Integer, Map<Integer, Integer>> newTransitionMap = Map.of();
        for (int newState = 0; newState < allStates.size(); newState++) {
            var state = allStates.get(newState);
            newTransitionMap.put(newState, Map.of());
            var newLocalTransitionMap = newTransitionMap.get(newState);
            var localTransitionMap = transitionMap.get(state);
            for (var pair : localTransitionMap.pairs()) {
                var letter = pair.get1();
                var neighborState = pair.get2();
                var newNeighborState = frozenSetToIndex.get(neighborState);
                newLocalTransitionMap.put(letter, newNeighborState);
            }
        }

        // determine newAcceptMap
        int nAlternatives = -1;
        Map<Integer, Integer> newAcceptMap = Map.of();
        for (var pair : acceptMap.pairs()) {
            var newState = frozenSetToIndex.get(pair.get1());
            nAlternatives = M.imax(nAlternatives, pair.get2());
            newAcceptMap.put(newState, pair.get2());
        }
        nAlternatives++;

        return new DFAIR(allStates.size(), 0, nAlternatives, newTransitionMap, newAcceptMap);
    }

    private final int nStates;
    private final int startState;
    private final int nAlternatives; // all mapped values in acceptMap must less than this value.
    private final Map<Integer, Map<Integer, Integer>> transitionMap;
    private final Map<Integer, Integer> acceptMap;

    private DFAIR(int nStates, int startState, int nAlternatives, Map<Integer, Map<Integer, Integer>> transitionMap,
            Map<Integer, Integer> acceptMap) {
        this.nStates = nStates;
        this.startState = startState;
        this.nAlternatives = nAlternatives;
        this.transitionMap = transitionMap;
        this.acceptMap = acceptMap;
    }

    private int transition(int state, int letter) {
        return transitionMap.get(state).getOrElse(letter, () -> -1);
    }

    private int transitionToGroupId(List<Integer> stateToGroupId, int state, int letter) {
        int transitionState = transition(state, letter);
        return transitionState < 0 ? -1 : stateToGroupId.get(transitionState);
    }

    /**
     * Returns an equivalent DFA with the minimum number of states
     *
     * In the dragon book, this algorithm is described in section 3.9.6 pages
     * 180-184
     */
    public DFA withMinimumNumberOfStates() {
        // initially, partition every state by their accept status.
        // groups 0..<nAlternatives are the various accept states.
        // the group indexed 'nAlternatives' are all the unaccepted states.
        // IO.println("acceptMap = " + acceptMap);
        var partition = List.ofSize(nAlternatives + 1, () -> List.<Integer>of());
        var stateToGroupId = List.ofSize(nStates, () -> 0);
        for (int state = 0; state < nStates; state++) {
            int groupId = acceptMap.getOptional(state).map(i -> i + 1).getOrElse(0);
            partition.get(groupId).add(state);
            stateToGroupId.set(state, groupId);
        }
        if (partition.get(0).size() == 0) {
            // the first group composed entirely of non-accepting states may potentially be
            // empty.
            partition = partition.sliceFrom(1);
        }
        for (int i = 0; i < partition.size(); i++) {
            Assert.that(partition.get(i).size() != 0);
        }

        // split the partitions
        while (true) {
            // we store the partition size because we will add to the partition
            // in the loop itself.
            int startPartitionSize = partition.size();
            for (int groupId = 0; groupId < startPartitionSize; groupId++) {
                for (int letter = 0; letter < Alphabet.COUNT; letter++) {

                    var statesByTransitionGroupIds = Map.<Integer, List<Integer>>of();
                    for (int state : partition.get(groupId)) {
                        int transitionGroupId = transitionToGroupId(stateToGroupId, state, letter);
                        statesByTransitionGroupIds.getOrInsert(transitionGroupId, () -> List.of()).add(state);
                    }
                    Assert.notEquals(statesByTransitionGroupIds.size(), 0);

                    if (statesByTransitionGroupIds.size() != 1) {
                        // the transition on this letter has split this group.
                        var resultingGroups = List.sorted(statesByTransitionGroupIds.values());

                        // let the first resulting group takes the place of the old group.
                        partition.set(groupId, resultingGroups.get(0));

                        // add the remaining groups at the end of the partition.
                        for (int i = 1; i < resultingGroups.size(); i++) {
                            int newGroupId = partition.size();
                            partition.add(resultingGroups.get(i));

                            // the 'stateToGroupId' table also needs to be updated to reflect the new
                            // groups that these states belong in.
                            for (var movedState : resultingGroups.get(i)) {
                                stateToGroupId.set(movedState, newGroupId);
                            }
                        }
                    }
                }
            }

            if (partition.size() == startPartitionSize) {
                // if no new groups were added to the partition, we're done
                break;
            }
        }

        // Now encode the resulting data into a DFA
        var stateRemap = new int[nStates];
        for (int newState = 0; newState < partition.size(); newState++) {
            for (int oldState : partition.get(newState)) {
                stateRemap[oldState] = newState;
            }
        }

        int newStartState = stateRemap[startState];

        var newTransitionMap = new int[partition.size() * Alphabet.COUNT];
        for (int i = 0; i < newTransitionMap.length; i++) {
            newTransitionMap[i] = -1;
        }
        for (var pair1 : transitionMap.pairs()) {
            int sourceState = stateRemap[pair1.get1()];
            for (var pair2 : pair1.get2().pairs()) {
                int letter = pair2.get1();
                int destinationState = stateRemap[pair2.get2()];
                newTransitionMap[sourceState * Alphabet.COUNT + letter] = destinationState;
            }
        }

        var newAcceptMap = new int[partition.size()];
        for (int i = 0; i < newAcceptMap.length; i++) {
            newAcceptMap[i] = -1;
        }
        for (var pair : acceptMap.pairs()) {
            int state = stateRemap[pair.get1()];
            newAcceptMap[state] = pair.get2();
        }

        return new DFA(newStartState, newTransitionMap, newAcceptMap);
    }

    /**
     * Used every now and then for debugging purposes.
     *
     * Converts this DFAIR directly into a DFA without minimizing state count.
     */
    public DFA toDFA() {
        // compute newTransitionMap
        var newTransitionMap = new int[nStates * Alphabet.COUNT];
        for (int i = 0; i < newTransitionMap.length; i++) {
            newTransitionMap[i] = -1;
        }
        for (var pair : transitionMap.pairs()) {
            int state1 = pair.get1();
            var localTransitionMap = pair.get2();
            for (var innerPair : localTransitionMap.pairs()) {
                int letter = innerPair.get1();
                int state2 = innerPair.get2();
                newTransitionMap[state1 * Alphabet.COUNT + letter] = state2;
            }
        }

        // compute newAcceptMap
        var newAcceptMap = new int[nStates];
        for (int i = 0; i < nStates; i++) {
            newAcceptMap[i] = acceptMap.getOrElse(i, () -> -1);
        }

        return new DFA(startState, newTransitionMap, newAcceptMap);
    }
}
