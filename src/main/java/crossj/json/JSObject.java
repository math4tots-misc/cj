package crossj.json;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Repr;

public final class JSObject extends JSON {
    private final Map<String, JSON> object;

    JSObject(Map<String, JSON> object) {
        this.object = object;
    }

    @Override
    public Map<String, JSON> getObject() {
        return object;
    }

    @Override
    public boolean isObject() {
        return true;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof JSObject && ((JSObject) other).object.equals(object);
    }

    @Override
    public int hashCode() {
        return List.sortedBy(object.pairs(), (a, b) -> a.get1().compareTo(b.get1())).hashCode();
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append('{');
        boolean first = true;
        for (var pair : object.pairs()) {
            if (!first) {
                sb.append(',');
            }
            sb.append(Repr.reprstr(pair.get1()));
            sb.append(':');
            sb.append(pair.get2());
        }
        sb.append('}');
        return sb.toString();
    }
}
