package crossj.cj.js;

import crossj.base.List;
import crossj.base.Str;
import crossj.cj.CJIRItem;

public final class CJJSReifiedType {
    private final CJIRItem item;
    private final List<CJJSReifiedType> args;

    public CJJSReifiedType(CJIRItem item, List<CJJSReifiedType> args) {
        this.item = item;
        this.args = args;
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CJJSReifiedType)) {
            return false;
        }
        var other = (CJJSReifiedType) obj;
        return item.getFullName().equals(other.item.getFullName()) && args.equals(other.args);
    }

    @Override
    public int hashCode() {
        return List.of(item.getFullName().hashCode(), args.hashCode()).hashCode();
    }

    @Override
    public String toString() {
        return args.isEmpty() ? item.getFullName()
                : item.getFullName() + "[" + Str.join(",", args.map(a -> a.toString())) + "]";
    }

    public CJIRItem getItem() {
        return item;
    }

    public boolean isNative() {
        return item.isNative();
    }

    boolean hasOwnDefinitionForMethod(String methodName) {
        var method = item.getMethodOrNull(methodName);
        return method != null && method.getBody().isPresent();
    }

    boolean hasOwnEmptyDefinitionForMethod(String methodName) {
        var method = item.getMethodOrNull(methodName);
        return method != null && method.getBody().isEmpty();
    }

    public List<CJJSReifiedType> getArgs() {
        return args;
    }
}
