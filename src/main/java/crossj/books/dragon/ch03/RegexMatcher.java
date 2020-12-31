package crossj.books.dragon.ch03;

import crossj.base.Str;
import crossj.base.StrIter;
import crossj.base.XError;

public final class RegexMatcher {
    private DFA dfa;
    private final StrIter iter;
    private int matchIndex = -1;
    private int matchStartPosition = -1;
    private int matchLineNumber = -1;
    private int matchColumnNumber = -1;
    private int currentLineNumber = 1;
    private int currentColumnNumber = 1;

    RegexMatcher(DFA dfa, String string) {
        this.dfa = dfa;
        this.iter = Str.iter(string);
    }

    /**
     * Replaces the regex used to match the current string.
     */
    public void useRegex(Regex regex) {
        dfa = regex.getDfa();
    }

    /**
     * Gets the underlying StrIter instance used to walk the string for matching.
     *
     * This can be used to detect the current position in the string and whether the
     * matcher has reached the end of the string
     */
    public StrIter getStrIter() {
        return iter;
    }

    /**
     * Tries to find the longest regex match starting from the current position.
     *
     * If the match is successful, true is returned, and the position is incremented
     * to just after the match.
     */
    public boolean match() {
        int state = dfa.getStartState();
        int startPosition = iter.getPosition();
        int startLineNumber = currentLineNumber;
        int startColumnNumber = currentColumnNumber;
        int lastMatchIndex = dfa.getMatchIndex(state);
        int lastMatchPosition = lastMatchIndex >= 0 ? startPosition : -1;
        int lastMatchEndLineNumber = -1;
        int lastMatchEndColumnNumber = -1;
        int runningLineNumber = currentLineNumber;
        int runningColumnNumber = currentColumnNumber;
        while (iter.hasCodePoint() && !dfa.isDeadState(state)) {
            var codePoint = iter.nextCodePoint();
            if (codePoint == '\n') {
                runningLineNumber++;
                runningColumnNumber = 1;
            } else {
                runningColumnNumber++;
            }
            state = dfa.transition(state, codePoint);
            int matchIndex = dfa.getMatchIndex(state);
            if (matchIndex >= 0) {
                lastMatchPosition = iter.getPosition();
                lastMatchIndex = matchIndex;
                lastMatchEndLineNumber = runningLineNumber;
                lastMatchEndColumnNumber = runningColumnNumber;
            }
        }
        if (lastMatchPosition == -1) {
            // no match found
            iter.setPosition(startPosition);
            matchStartPosition = -1;
            matchIndex = -1;
            matchLineNumber = -1;
            matchColumnNumber = -1;
            currentLineNumber = startLineNumber;
            currentColumnNumber = startColumnNumber;
            return false;
        } else {
            // match found
            iter.setPosition(lastMatchPosition);
            matchStartPosition = startPosition;
            matchIndex = lastMatchIndex;
            matchLineNumber = startLineNumber;
            matchColumnNumber = startColumnNumber;
            currentLineNumber = lastMatchEndLineNumber;
            currentColumnNumber = lastMatchEndColumnNumber;
            return true;
        }
    }

    /**
     * Like match(), but requires that the entire string matches to the end.
     */
    public boolean matchAll() {
        int startPosition = iter.getPosition();
        if (match()) {
            if (iter.hasCodePoint()) {
                // the longest possible match didn't reach the end, so
                // the match actually fails.
                iter.setPosition(startPosition);
                matchStartPosition = -1;
                matchIndex = -1;
                return false;
            } else {
                return true;
            }
        } else {
            return false;
        }
    }

    /**
     * After a successful match(), calling this method returns the index of the
     * matching pattern of the associated Regex.
     */
    public int getMatchIndex() {
        return matchIndex;
    }

    public int getMatchLength() {
        return iter.getPosition() - matchStartPosition;
    }

    public boolean atZeroLengthMatch() {
        return getMatchLength() == 0;
    }

    /**
     * After a successful match(), calling this method returns the matching section
     * of the text.
     */
    public String getMatchText() {
        if (matchIndex == -1) {
            throw XError.withMessage("getMatchText() after a failed match");
        }
        return iter.sliceFrom(matchStartPosition);
    }

    public int getFirstCodePointOfMatch() {
        if (matchIndex == -1) {
            throw XError.withMessage("getFirstCodePointOfMatch() after a failed match");
        }
        if (matchStartPosition >= iter.getPosition()) {
            throw XError.withMessage("getFirstCodePointOfMatch() on zero length match");
        }
        int savedPosition = iter.getPosition();
        iter.setPosition(matchStartPosition);
        int codePoint = iter.peekCodePoint();
        iter.setPosition(savedPosition);
        return codePoint;
    }

    /**
     * Returns the line number of the start of the last match
     *
     * NOTE: return value of this method is invalidated if the underlying
     * StrIter is moved externally.
     */
    public int getMatchLineNumber() {
        return matchLineNumber;
    }

    /**
     * Returns the column number of the start of the last match
     *
     * NOTE: return value of this method is invalidated if the underlying
     * StrIter is moved externally.
     */
    public int getMatchColumnNumber() {
        return matchColumnNumber;
    }

    public int getCurrentLineNumber() {
        return currentLineNumber;
    }

    public int getCurrentColumnNumber() {
        return currentColumnNumber;
    }
}
