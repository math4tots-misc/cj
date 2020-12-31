package crossj.cj;

import crossj.base.List;
import crossj.base.Str;

public final class CJError extends RuntimeException {
    private static final long serialVersionUID = 1L;
    private final String message;
    private final List<CJMark> marks;

    CJError(String message, List<CJMark> marks) {
        super(message);
        this.message = message;
        this.marks = marks;
    }

    public static CJError of(String message, CJMark... marks) {
        return new CJError(message, List.fromJavaArray(marks));
    }

    @Override
    public String getMessage() {
        return message;
    }

    public List<CJMark> getMarks() {
        return marks;
    }

    @Override
    public String toString() {
        return message + Str.join("", marks.map(m -> "\n" + m.repr()));
    }
}
