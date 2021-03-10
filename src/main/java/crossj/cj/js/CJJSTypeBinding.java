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
    private final CJIRClassType selfType;
    private final Map<String, CJIRClassType> itemLevelMap;
    private final Map<String, CJIRClassType> methodLevelMap;
    private final List<CJIRClassType> methodLevelArgs;

    CJJSTypeBinding(CJIRClassType selfType, Map<String, CJIRClassType> itemLevelMap,
            Map<String, CJIRClassType> methodLevelMap, List<CJIRClassType> methodLevelArgs) {
        this.selfType = selfType;
        this.itemLevelMap = itemLevelMap;
        this.methodLevelMap = methodLevelMap;
        this.methodLevelArgs = methodLevelArgs;
    }

    public CJIRClassType getSelfType() {
        return selfType;
    }

    static CJJSTypeBinding empty(CJIRClassType selfType) {
        return new CJJSTypeBinding(selfType, Map.of(), Map.of(), List.of());
    }

    CJJSLLMethod translate(CJIRClassType owner, CJIRReifiedMethodRef reifiedMethodRef) {
        var methodRef = reifiedMethodRef.getMethodRef();
        var methodOwner = methodRef.getOwner();
        Map<String, CJIRClassType> itemLevelMap = Map.of();
        var itemTypeParameters = methodOwner.getItem().getTypeParameters();
        for (int i = 0; i < itemTypeParameters.size(); i++) {
            var typeParameter = itemTypeParameters.get(i);
            var type = methodOwner.getArgs().get(i);
            itemLevelMap.put(typeParameter.getName(), apply(type));
        }
        var methodTypeParameters = methodRef.getMethod().getTypeParameters();
        var methodLevelArgs = List.<CJIRClassType>of();
        Map<String, CJIRClassType> methodLevelMap = Map.of();
        for (int i = 0; i < methodTypeParameters.size(); i++) {
            var typeParameter = methodTypeParameters.get(i);
            var type = reifiedMethodRef.getTypeArgs().get(i);
            var atype = apply(type);
            methodLevelMap.put(typeParameter.getName(), atype);
            methodLevelArgs.add(atype);
        }
        var binding = new CJJSTypeBinding(owner, itemLevelMap, methodLevelMap, methodLevelArgs);
        return new CJJSLLMethod(owner, methodRef.getMethod(), binding);
    }

    boolean isEmpty() {
        return methodLevelMap.size() == 0 && selfType.getArgs().isEmpty();
    }

    CJIRClassType get(String variableName) {
        var ret = methodLevelMap.getOrNull(variableName);
        return ret != null ? ret : itemLevelMap.get(variableName);
    }

    @Override
    public String toString() {
        return Str.join(",", selfType.getArgs().map(a -> a.repr())) + "+"
                + Str.join(",", methodLevelArgs.map(a -> a.repr()));
    }

    CJIRClassType apply(CJIRType type) {
        return type.accept(new CJIRTypeVisitor<CJIRClassType, Void>() {

            @Override
            public CJIRClassType visitClass(CJIRClassType t, Void a) {
                return new CJIRClassType(t.getItem(), t.getArgs().map(arg -> apply(arg)));
            }

            @Override
            public CJIRClassType visitVariable(CJIRVariableType t, Void a) {
                return get(t.getName());
            }

            @Override
            public CJIRClassType visitSelf(CJIRSelfType t, Void a) {
                return selfType;
            }
        }, null);
    }
}
