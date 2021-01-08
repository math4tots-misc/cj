package crossj.cj;

import crossj.base.List;
import crossj.base.Map;

/**
 * Javascript Translation Context
 */
public final class CJJSContext {
    private int nextTempVarId = 0;
    private final boolean stackEnabled;
    private final List<String> fileNamesForStack = List.of();
    private final Map<String, Integer> fileNameMap = Map.of();
    private final List<CJMark> marksForStack = List.of();
    private final Map<CJMark, Integer> markMap = Map.of();

    public CJJSContext(boolean stackEnabled) {
        this.stackEnabled = stackEnabled;
    }

    void resetVarIds() {
        nextTempVarId = 0;
    }

    String newTempVarName() {
        return "L$" + nextTempVarId++;
    }

    public boolean isStackEnabled() {
        return stackEnabled;
    }

    public List<String> getFileNamesForStack() {
        return fileNamesForStack;
    }

    public List<CJMark> getMarksForStack() {
        return marksForStack;
    }

    int addMark(CJMark mark) {
        return markMap.getOrInsert(mark, () -> {
            var i = marksForStack.size();
            addFileName(mark.filename);
            marksForStack.add(mark);
            return i;
        });
    }

    public int getFileNameIndex(String fileName) {
        return fileNameMap.get(fileName);
    }

    private int addFileName(String fileName) {
        return fileNameMap.getOrInsert(fileName, () -> {
            var i = fileNamesForStack.size();
            fileNamesForStack.add(fileName);
            return i;
        });
    }
}
