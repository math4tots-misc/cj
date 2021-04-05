package crossj.cj.ir;

public final class CJIRFieldMethodInfo extends CJIRExtraMethodInfo {
    private final CJIRField field;
    private final String kind;

    public CJIRFieldMethodInfo(CJIRField field, String kind) {
        this.field = field;
        this.kind = kind;
    }

    public CJIRField getField() {
        return field;
    }

    public String getKind() {
        return kind;
    }
}
