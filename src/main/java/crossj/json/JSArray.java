package crossj.json;

import crossj.base.List;

public final class JSArray extends JSON {
    private final List<JSON> array;

    JSArray(List<JSON> array) {
        this.array = array;
    }

    @Override
    public List<JSON> getArray() {
        return array;
    }

    @Override
    public boolean isArray() {
        return true;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof JSArray && ((JSArray) other).array.equals(array);
    }

    @Override
    public int hashCode() {
        return array.hashCode();
    }

    @Override
    public String toString() {
        return array.toString();
    }
}
