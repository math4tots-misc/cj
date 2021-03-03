package crossj.json;

import crossj.base.List;
import crossj.base.Map;
import crossj.cj.CJError;

/**
 * A JSON value
 */
public abstract class JSON {

    public static JSON parse(String string) {
        return JSONParser.parse(string);
    }

    public static JSNull of() {
        return JSNull.instance;
    }

    public static JSON of(Object obj) {
        if (obj == null) {
            return of();
        } else if (obj instanceof JSON) {
            return (JSON) obj;
        } else if (obj instanceof Boolean) {
            return of((boolean) obj);
        } else if (obj instanceof Double) {
            return of((double) obj);
        } else if (obj instanceof String) {
            return of((String) obj);
        } else if (obj instanceof List<?>) {
            return of(((List<?>) obj).map(JSON::of));
        } else if (obj instanceof Map<?, ?>) {
            var map = Map.<String, JSON>of();
            for (var pair : ((Map<?, ?>) obj).pairs()) {
                var key = of(pair.get1()).getString();
                var value = of(pair.get2());
                map.put(key, value);
            }
            return of(map);
        }
        throw CJError.of(obj + " cannot be converted to JSON");
    }

    public static JSBool of(boolean value) {
        return new JSBool(value);
    }

    public static JSNumber of(double value) {
        return new JSNumber(value);
    }

    public static JSString of(String value) {
        return new JSString(value);
    }

    public static JSArray of(List<JSON> value) {
        return new JSArray(value);
    }

    public static JSObject of(Map<String, JSON> value) {
        return new JSObject(value);
    }

    public static JSArray array(Object... values) {
        return new JSArray(List.fromJavaArray(values).map(JSON::of));
    }

    public static JSObject object(Object... args) {
        Map<String, JSON> map = Map.of();
        for (int i = 0; i < args.length; i += 2) {
            var key = (String) args[i];
            var value = of(args[i + 1]);
            map.put(key, value);
        }
        return new JSObject(map);
    }

    public boolean isBool() {
        return false;
    }

    public boolean isNumber() {
        return false;
    }

    public boolean isString() {
        return false;
    }

    public boolean isArray() {
        return false;
    }

    public boolean isObject() {
        return false;
    }

    public boolean isNull() {
        return false;
    }

    public boolean getBool() {
        throw CJError.of(this + "is not a Bool");
    }

    public double getNumber() {
        throw CJError.of(this + "is not a Number");
    }

    public String getString() {
        throw CJError.of(this + "is not a String");
    }

    public List<JSON> getArray() {
        throw CJError.of(this + "is not a Array");
    }

    public Map<String, JSON> getObject() {
        throw CJError.of(this + "is not a Object");
    }

    public JSON get(String key) {
        return getObject().get(key);
    }

    public JSON get(int i) {
        return getArray().get(i);
    }

    public int size() {
        return isArray() ? getArray().size() : getObject().size();
    }

    @Override
    public abstract boolean equals(Object other);

    @Override
    public abstract int hashCode();

    @Override
    public abstract String toString();
}
