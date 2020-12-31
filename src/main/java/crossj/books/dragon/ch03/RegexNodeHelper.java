package crossj.books.dragon.ch03;

final class RegexNodeHelper {
    private RegexNodeHelper() {}

    static String wrap(RegexNode node, int outerPrecedence) {
        return node.getBindingPrecedence() < outerPrecedence ? "(" + node.toPattern() + ")" : node.toPattern();
    }
}
