package crossj.cj;

import crossj.base.Assert;
import crossj.base.FS;
import crossj.base.List;
import crossj.base.Map;

public final class CJJSSink {
    private final StringBuilder src = new StringBuilder();
    private final List<String> sources = List.of();
    private final Map<String, Integer> sourceIdsByName = Map.of();
    private final StringBuilder mapping = new StringBuilder();
    private int currentGeneratedColumn = 0;
    private int lastGeneratedColumn = 0;
    private int lastSourceId = 0;
    private int lastSourceLine = 0;
    private int lastSourceColumn = 0;
    private boolean generatedLineStart = true;

    public String getSource(String outFilePath) {
        var index = outFilePath.lastIndexOf(FS.getSeparator());
        var outFileName = index == -1 ? outFilePath : outFilePath.substring(index + 1);
        return src.toString() + "\n//# sourceMappingURL=" + outFileName + ".map";
    }

    public String getSourceMap(String outFileName) {
        var sb = new StringBuilder();
        sb.append("{\"version\":3,");
        sb.append("\"file\":\"" + outFileName + "\",");
        sb.append("\"sourceRoot\":\"../\","); // TODO: address this hack
        sb.append("\"sources\":[");
        for (int i = 0; i < sources.size(); i++) {
            if (i > 0) {
                sb.append(',');
            }
            sb.append('"');
            sb.append(sources.get(i));
            sb.append('"');
        }
        sb.append("],");
        sb.append("\"names\":[],");
        sb.append("\"mappings\":\"");
        sb.append(mapping.toString());
        sb.append("\"}");
        return sb.toString();
    }

    public void append(String string) {
        int ch;
        for (int i = 0; i < string.length(); i += Character.charCount(ch)) {
            ch = string.codePointAt(i);
            if (ch == '\n') {
                mapping.append(';');
                currentGeneratedColumn = 0;
                lastGeneratedColumn = 0;
                generatedLineStart = true;
            } else {
                currentGeneratedColumn++;
            }
            src.appendCodePoint(ch);
        }
    }

    public void addMark(CJMark mark) {
        addMapping(mark.filename, mark.line > 0 ? mark.line - 1 : 0, mark.column > 0 ? mark.column - 1 : 0);
    }

    private void addMapping(String sourceFileName, int sourceLine, int sourceColumn) {
        var sourceId = getSourceId(sourceFileName);

        var generatedColumnDiff = currentGeneratedColumn - lastGeneratedColumn;
        var sourceIdDiff = sourceId - lastSourceId;
        var sourceLineDiff = sourceLine - lastSourceLine;
        var sourceColumnDiff = sourceColumn - lastSourceColumn;

        if (generatedLineStart) {
            generatedLineStart = false;
        } else {
            mapping.append(',');
        }

        mapping.append(encode(generatedColumnDiff));
        mapping.append(encode(sourceIdDiff));
        mapping.append(encode(sourceLineDiff));
        mapping.append(encode(sourceColumnDiff));

        lastGeneratedColumn = currentGeneratedColumn;
        lastSourceId = sourceId;
        lastSourceLine = sourceLine;
        lastSourceColumn = sourceColumn;
    }

    private int getSourceId(String sourceFileName) {
        var id = sourceIdsByName.getOrNull(sourceFileName);
        if (id != null) {
            return id;
        } else {
            id = sources.size();
            sources.add(sourceFileName);
            sourceIdsByName.put(sourceFileName, id);
            return id;
        }
    }

    /**
     * Base 64 VLQ encoding of an integer value
     */
    private String encode(int x) {
        var sb = new StringBuilder();
        var negative = 0;
        if (x < 0) {
            negative = 1;
            x = -x;
        }
        var firstChunk = x % 16;
        x /= 16;
        var firstCont = x != 0 ? 32 : 0;
        sb.append(_digit(firstCont + firstChunk * 2 + negative));
        while (x != 0) {
            var chunk = x % 32;
            x /= 32;
            var cont = x != 0 ? 32 : 0;
            sb.append(_digit(cont + chunk));
        }
        return sb.toString();
    }

    /**
     * Converts a numeric digit to a base64 digit
     */
    private static char _digit(int d) {
        if (d < 0 || d >= 64) {
            throw new RuntimeException("Invalid base64 digit: " + d);
        } else if (d <= 25) {
            return (char) ('A' + d);
        } else if (d <= 51) {
            return (char) ('a' + d - 26);
        } else if (d <= 61) {
            return (char) ('0' + d - 52);
        } else if (d == 62) {
            return '+';
        } else {
            Assert.equals(d, 63);
            return '/';
        }
    }
}
