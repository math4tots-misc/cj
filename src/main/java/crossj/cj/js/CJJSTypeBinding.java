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
    private final CJJSReifiedType selfType;
    private final Map<String, CJJSReifiedType> itemLevelMap;
    private final Map<String, CJJSReifiedType> methodLevelMap;
    private final List<CJJSReifiedType> methodLevelArgs;

    CJJSTypeBinding(CJJSReifiedType selfType, Map<String, CJJSReifiedType> itemLevelMap,
            Map<String, CJJSReifiedType> methodLevelMap, List<CJJSReifiedType> methodLevelArgs) {
        this.selfType = selfType;
        this.itemLevelMap = itemLevelMap;
        this.methodLevelMap = methodLevelMap;
        this.methodLevelArgs = methodLevelArgs;
    }

    public CJJSReifiedType getSelfType() {
        return selfType;
    }

    static CJJSTypeBinding empty(CJJSReifiedType selfType) {
        return new CJJSTypeBinding(selfType, Map.of(), Map.of(), List.of());
    }

    CJJSReifiedMethod translate(CJJSReifiedType owner, CJIRReifiedMethodRef reifiedMethodRef) {
        var methodRef = reifiedMethodRef.getMethodRef();
        var methodOwner = methodRef.getOwner();
        Map<String, CJJSReifiedType> itemLevelMap = Map.of();
        var itemTypeParameters = methodOwner.getItem().getTypeParameters();
        for (int i = 0; i < itemTypeParameters.size(); i++) {
            var typeParameter = itemTypeParameters.get(i);
            var type = methodOwner.getArgs().get(i);
            itemLevelMap.put(typeParameter.getName(), apply(type));
        }
        var methodTypeParameters = methodRef.getMethod().getTypeParameters();
        var methodLevelArgs = List.<CJJSReifiedType>of();
        Map<String, CJJSReifiedType> methodLevelMap = Map.of();
        for (int i = 0; i < methodTypeParameters.size(); i++) {
            var typeParameter = methodTypeParameters.get(i);
            var type = reifiedMethodRef.getTypeArgs().get(i);
            var atype = apply(type);
            methodLevelMap.put(typeParameter.getName(), atype);
            methodLevelArgs.add(atype);
        }
        var binding = new CJJSTypeBinding(owner, itemLevelMap, methodLevelMap, methodLevelArgs);
        return new CJJSReifiedMethod(owner, methodRef.getMethod(), binding);
    }

    boolean isEmpty() {
        return methodLevelMap.size() == 0 && selfType.getArgs().isEmpty();
    }

    CJJSReifiedType get(String variableName) {
        var ret = methodLevelMap.getOrNull(variableName);
        return ret != null ? ret : itemLevelMap.get(variableName);
    }

    @Override
    public String toString() {
        return Str.join(",", selfType.getArgs()) + "+" + Str.join(",", methodLevelArgs);
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
                return selfType;
            }
        }, null);
    }
}
