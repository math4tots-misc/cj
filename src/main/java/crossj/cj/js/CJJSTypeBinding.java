package crossj.cj.js;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Str;
import crossj.cj.CJIRClassType;
import crossj.cj.CJIRSelfType;
import crossj.cj.CJIRType;
import crossj.cj.CJIRTypeVisitor;
import crossj.cj.CJIRVariableType;

final class CJJSTypeBinding {
    private final Map<String, CJJSReifiedType> map;

    CJJSTypeBinding(Map<String, CJJSReifiedType> map) {
        this.map = map;
    }

    static CJJSTypeBinding empty() {
        return new CJJSTypeBinding(Map.of());
    }

    boolean isEmpty() {
        return map.size() == 0;
    }

    CJJSReifiedType get(String variableName) {
        return map.get(variableName);
    }

    @Override
    public String toString() {
        return Str.join(",", List.sortedBy(map.pairs(), (a, b) -> a.get1().compareTo(b.get1()))
                .map(pair -> pair.get1() + ":" + pair.get2()));
    }

    CJJSReifiedType apply(CJIRType type) {
        return type.accept(new CJIRTypeVisitor<CJJSReifiedType, Void>() {

            @Override
            public CJJSReifiedType visitClass(CJIRClassType t, Void a) {
                return new CJJSReifiedType(t.getItem(), t.getArgs().map(arg -> apply(arg)));
            }

            @Override
            public CJJSReifiedType visitVariable(CJIRVariableType t, Void a) {
                return get(t.getName());
            }

            @Override
            public CJJSReifiedType visitSelf(CJIRSelfType t, Void a) {
                return get("Self");
            }
        }, null);
    }
}
