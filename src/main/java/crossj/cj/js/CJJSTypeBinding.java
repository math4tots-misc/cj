package crossj.cj.js;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Str;
import crossj.cj.CJIRClassType;
import crossj.cj.CJIRReifiedMethodRef;
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

    CJJSReifiedMethod translate(CJJSReifiedType owner, CJIRReifiedMethodRef reifiedMethodRef) {
        Map<String, CJJSReifiedType> map = Map.of();
        map.put("Self", owner);
        var methodRef = reifiedMethodRef.getMethodRef();
        var methodOwner = methodRef.getOwner();
        var itemTypeParameters = methodOwner.getItem().getTypeParameters();
        for (int i = 0; i < itemTypeParameters.size(); i++) {
            var typeParameter = itemTypeParameters.get(i);
            var type = methodOwner.getArgs().get(i);
            map.put(typeParameter.getName(), apply(type));
        }
        var methodTypeParameters = methodRef.getMethod().getTypeParameters();
        for (int i = 0; i < methodTypeParameters.size(); i++) {
            var typeParameter = methodTypeParameters.get(i);
            var type = reifiedMethodRef.getTypeArgs().get(i);
            map.put(typeParameter.getName(), apply(type));
        }
        var binding = new CJJSTypeBinding(map);
        return new CJJSReifiedMethod(owner, methodRef.getMethod(), binding);
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
