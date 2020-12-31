package crossj.books.dragon.ch03;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Range;
import crossj.base.Set;

/**
 * Regex character classes
 */
final class CharSetRegexNode implements RegexNode {
    public final static int BINDING_PRECEDENCE = LetterRegexNode.BINIDNG_PRECEDENCE;

    public final static CharSetRegexNode ALL = new CharSetRegexNode(".", Range.of(0, Alphabet.COUNT).list());
    public final static CharSetRegexNode DIGITS = new CharSetRegexNode("\\d", Range.of('0', '9' + 1).list());
    public final static CharSetRegexNode NON_DIGITS = DIGITS.negate("\\D");
    public final static CharSetRegexNode WORD = new CharSetRegexNode("\\w",
            List.of(Range.of('0', '9' + 1), Range.of('a', 'z' + 1), Range.of('A', 'Z' + 1), List.of((int) '_'))
                    .flatMap(i -> i));
    public final static CharSetRegexNode NON_WORD = WORD.negate("\\W");
    public final static CharSetRegexNode WHITESPACE = new CharSetRegexNode("\\s", List.of(
            // https://developer.mozilla.org/en-US/docs/Glossary/Whitespace
            0x09, // tab ('\t')
            0x0a, // newline ('\n')
            0x0b, // vertical tab ('\v')
            0x0c, // formfeed ('\f')
            0x0d, // carriage return ('\r')
            0x20 // space (' ')
    ));
    public final static CharSetRegexNode NON_WHITESPACE = WHITESPACE.negate("\\S");

    private final String name;
    private final List<Integer> letterList;
    private final Set<Integer> letterSet;

    CharSetRegexNode(String name, List<Integer> letterList) {
        for (int letter : letterList) {
            Assert.that(Alphabet.contains(letter));
        }
        this.name = name;
        this.letterList = List.sorted(letterList);
        this.letterSet = Set.fromIterable(letterList);
    }

    @Override
    public int getBindingPrecedence() {
        return BINDING_PRECEDENCE;
    }

    @Override
    public String toPattern() {
        return name;
    }

    @Override
    public void buildBlock(NFABuilder builder, int startState, int acceptState) {
        for (var letter : letterList) {
            builder.connect(startState, Optional.of(letter), acceptState);
        }
    }

    CharSetRegexNode negate(String name) {
        return new CharSetRegexNode(name, Range.of(0, Alphabet.COUNT).filter(c -> !letterSet.contains(c)).list());
    }

    public List<Integer> getLetterList() {
        return letterList;
    }
}
