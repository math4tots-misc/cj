package crossj.books.dragon.ch03;

import crossj.base.Char;
import crossj.base.Num;
import crossj.base.Set;
import crossj.base.Str;
import crossj.base.StrIter;
import crossj.base.Try;
import crossj.base.XError;

final class RegexNodeParser {

    public static Try<RegexNode> parse(String pattern) {
        return new RegexNodeParser(Str.iter(pattern)).parseAll();
    }

    private final StrIter iter;

    RegexNodeParser(StrIter iter) {
        this.iter = iter;
    }

    private boolean at(char c) {
        return iter.hasCodePoint() && iter.peekCodePoint() == c;
    }

    private boolean consume(char c) {
        if (at(c)) {
            iter.nextCodePoint();
            return true;
        } else {
            return false;
        }
    }

    private Try<RegexNode> parseAll() {
        var tryNode = parseAltExpr();
        if (tryNode.isOk() && iter.hasCodePoint()) {
            return Try.fail("Invalid trailing data in regex pattern: " + iter.getString());
        } else {
            return tryNode;
        }
    }

    private Try<RegexNode> parseAltExpr() {
        var tryNode = parseCatExpr();
        while (tryNode.isOk() && consume('|')) {
            tryNode = tryNode.flatMap(lhs -> parseCatExpr().map(rhs -> lhs.or(rhs)));
        }
        return tryNode;
    }

    private Try<RegexNode> parseCatExpr() {
        var tryNode = Try.ok(RegexNode.epsilon());
        while (tryNode.isOk() && iter.hasCodePoint() && !at(')') && !at('|')) {
            tryNode = tryNode.flatMap(lhs -> parsePostfix().map(rhs -> lhs.and(rhs)));
        }
        return tryNode;
    }

    private Try<Integer> parseDigits() {
        if (!iter.hasCodePoint()) {
            return Try.fail("Expected digit but got end of string");
        } else if (!Char.isDigit(iter.peekCodePoint())) {
            return Try.fail("Expected digit but got " + Str.fromCodePoint(iter.nextCodePoint()));
        }
        int start = iter.getPosition();
        while (iter.hasCodePoint() && Char.isDigit(iter.peekCodePoint())) {
            iter.nextCodePoint();
        }
        return Try.ok(Num.parseInt(iter.sliceFrom(start)));
    }

    private Try<RegexNode> parsePostfix() {
        var tryNode = parseAtom();
        if (tryNode.isOk() && iter.hasCodePoint()) {
            switch (iter.peekCodePoint()) {
                case '+':
                    tryNode = tryNode.map(node -> node.plus());
                    iter.nextCodePoint();
                    break;
                case '*':
                    tryNode = tryNode.map(node -> node.star());
                    iter.nextCodePoint();
                    break;
                case '?':
                    tryNode = tryNode.map(node -> node.qmark());
                    iter.nextCodePoint();
                    break;
                case '{':
                    iter.nextCodePoint();
                    var tryMin = parseDigits();
                    if (tryMin.isFail()) {
                        return tryMin.withContext("while parsing lower limit in interval syntax {}").castFail();
                    }
                    int min = tryMin.get();
                    int vmax = min;
                    if (consume(',')) {
                        if (consume('}')) {
                            vmax = -1;
                        } else {
                            var tryMax = parseDigits();
                            if (tryMax.isFail()) {
                                return tryMax.withContext("while parsing upper limit in interval syntax {}").castFail();
                            }
                            if (!consume('}')) {
                                return Try.fail("Expected closing '}'");
                            }
                            vmax = tryMax.get();
                        }
                    } else if (!consume('}')) {
                        return Try.fail("Expected closing '}'");
                    }
                    int max = vmax;
                    tryNode = tryNode.map(node -> new IntervalRegexNode(node, min, max));
                    break;
            }
        }
        return tryNode;
    }

    private Try<RegexNode> parseAtom() {
        int code = iter.nextCodePoint();
        switch (code) {
            case '\\':
                if (iter.hasCodePoint()) {
                    var escape = iter.nextCodePoint();
                    switch (escape) {
                        case '\\':
                        case '+':
                        case '*':
                        case '?':
                        case '(':
                        case ')':
                        case '[':
                        case ']':
                        case '{':
                        case '}':
                        case '|':
                        case '.':
                        case '$':
                            return Try.ok(RegexNode.ofCodePoint(escape));
                        case 'n':
                            return Try.ok(RegexNode.ofChar('\n'));
                        case 'r':
                            return Try.ok(RegexNode.ofChar('\r'));
                        case 't':
                            return Try.ok(RegexNode.ofChar('\t'));
                        case 'd':
                            return Try.ok(CharSetRegexNode.DIGITS);
                        case 'D':
                            return Try.ok(CharSetRegexNode.NON_DIGITS);
                        case 'w':
                            return Try.ok(CharSetRegexNode.WORD);
                        case 'W':
                            return Try.ok(CharSetRegexNode.NON_WORD);
                        case 's':
                            return Try.ok(CharSetRegexNode.WHITESPACE);
                        case 'S':
                            return Try.ok(CharSetRegexNode.NON_WHITESPACE);
                        default:
                            return Try.fail("Invalid escape character " + escape + " in :" + iter.getString());
                    }
                } else {
                    return Try.fail("Regex pattern ends in unterminated escape sequence: " + iter.getString());
                }
            case '.':
                return Try.ok(CharSetRegexNode.ALL);
            case '(': {
                var tryNode = parseAltExpr();
                if (tryNode.isOk() && (!iter.hasCodePoint() || iter.nextCodePoint() != ')')) {
                    return Try.fail("Unmatched open parenthesis in regex: " + iter.getString());
                }
                return tryNode;
            }
            case '*':
            case '+':
            case '?':
            case '{':
            case '}':
                return Try.fail("Misplaced postfix operator in regex: " + iter.getString());
            case '|':
                throw XError.withMessage("Internal regex parsing issue (|): " + iter.getString());
            case ')':
                return Try.fail("Unexpected close parenthesis in regex: " + iter.getString());
            case '[': {
                var startPosition = iter.getPosition();
                var negate = consume('^');
                var letters = Set.<Integer>of();
                while (iter.hasCodePoint() && !at(']')) {
                    int letter = iter.nextCodePoint();
                    if (isRangeableLetter(letter) && consume('-')) {
                        if (isRangeableLetter(iter.peekCodePoint())) {
                            // range (e.g. 0-9 or A-H)
                            var upper = iter.nextCodePoint();
                            for (int i = letter; i <= upper; i++) {
                                letters.add(i);
                            }
                        } else if (at(']')) {
                            // ends with '-'
                            // it's just another letter
                            letters.add(letter);
                            letters.add((int) '-');
                        } else {
                            return Try.fail("Range starting " + Str.fromCodePoint(letter) + "- never terminated");
                        }
                    } else {
                        if (letter == '\\' && iter.hasCodePoint()) {
                            int escape = iter.nextCodePoint();
                            switch (escape) {
                                case 'd':
                                    letters.addAll(CharSetRegexNode.DIGITS.getLetterList());
                                    break;
                                case 'D':
                                    letters.addAll(CharSetRegexNode.NON_DIGITS.getLetterList());
                                    break;
                                case 'w':
                                    letters.addAll(CharSetRegexNode.WORD.getLetterList());
                                    break;
                                case 'W':
                                    letters.addAll(CharSetRegexNode.NON_WORD.getLetterList());
                                    break;
                                case 's':
                                    letters.addAll(CharSetRegexNode.WHITESPACE.getLetterList());
                                    break;
                                case 'S':
                                    letters.addAll(CharSetRegexNode.NON_WHITESPACE.getLetterList());
                                    break;
                                case '\\':
                                case '+':
                                case '*':
                                case '?':
                                case '(':
                                case ')':
                                case '[':
                                case ']':
                                case '{':
                                case '}':
                                case '|':
                                case '.':
                                case '-':
                                    letters.add(escape);
                                    break;
                                default:
                                    return Try.fail("Unexpected character escaped in character class: " + letter + ", "
                                            + iter.getString());
                            }
                        } else {
                            letters.add(letter);
                        }
                    }
                }
                var name = "[" + iter.sliceFrom(startPosition) + "]";
                if (!consume(']')) {
                    return Try.fail("Unmatched open bracket in regex: " + iter.getString());
                }
                var charClass = new CharSetRegexNode(name, letters.iter().list());
                if (negate) {
                    charClass = charClass.negate(name);
                }
                return Try.ok(charClass);
            }
            case ']':
                return Try.fail("Unexpected close bracket in regex: " + iter.getString());
            default:
                return Try.ok(RegexNode.ofCodePoint(code));
        }
    }

    private static boolean isRangeableLetter(int letter) {
        return ('a' <= letter && letter <= 'z') || ('A' <= letter && letter <= 'Z') || ('0' <= letter && letter <= '9');
    }
}
