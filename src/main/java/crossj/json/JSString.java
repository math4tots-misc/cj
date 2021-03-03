package crossj.json;

import crossj.base.Repr;

public final class JSString extends JSON {
    private final String string;

    JSString(String string) {
        this.string = string;
    }

    @Override
    public String getString() {
        return string;
    }

    @Override
    public boolean isString() {
        return true;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof JSString && ((JSString) other).string.equals(string);
    }

    @Override
    public int hashCode() {
        return string.hashCode();
    }

    @Override
    public String toString() {
        return Repr.reprstr(string);
    }
}
