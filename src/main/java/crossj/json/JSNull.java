package crossj.json;

public final class JSNull extends JSON {

    static final JSNull instance = new JSNull();

    private JSNull() {}

    @Override
    public boolean isNull() {
        return true;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof JSNull;
    }

    @Override
    public int hashCode() {
        return 631;
    }

    @Override
    public String toString() {
        return "null";
    }
}
