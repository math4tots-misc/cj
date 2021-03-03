package crossj.json;

public final class JSBool extends JSON {
    private final boolean bool;

    JSBool(boolean bool) {
        this.bool = bool;
    }

    @Override
    public boolean getBool() {
        return bool;
    }

    @Override
    public boolean isBool() {
        return true;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof JSBool && ((JSBool) other).bool == bool;
    }

    @Override
    public int hashCode() {
        return Boolean.hashCode(bool);
    }

    @Override
    public String toString() {
        return bool ? "true" : "false";
    }
}
