package crossj.cj;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Pair;
import crossj.cj.ast.CJAstTypeParameter;

public final class CJIRBinding {
    private final CJIRType selfType;
    private final Map<String, CJIRType> map;

    public CJIRBinding(CJIRType selfType, Map<String, CJIRType> map) {
        this.selfType = selfType;
        this.map = map;
    }

    public static CJIRBinding empty(CJIRType selfType) {
        return new CJIRBinding(selfType, Map.of());
    }

    void put(String key, CJIRType type) {
        map.put(key, type);
    }

    public boolean containsKey(String key) {
        return map.containsKey(key);
    }

    public CJIRType get(String key) {
        return map.get(key);
    }

    public CJIRType getSelfType() {
        return selfType;
    }

    public boolean isEmpty() {
        return map.size() == 0;
    }

    /**
     * Naively apply the binding. The resulting type is not checked for whether all
     * traits are properly implemented.
     *
     * @param type
     * @param marks
     * @return
     */
    CJIRType apply(CJIRType type, CJMark... marks) {
        return type.accept(new CJIRTypeVisitor<CJIRType, Void>() {

            @Override
            public CJIRType visitClass(CJIRClassType t, Void a) {
                var args = t.getArgs().map(arg -> arg.accept(this, a));
                return new CJIRClassType(t.getItem(), args);
            }

            @Override
            public CJIRType visitVariable(CJIRVariableType t, Void a) {
                var name = t.getName();
                var newType = map.getOrNull(name);
                if (newType == null) {
                    throw CJError.of("No binding for type variable " + name + " found", marks);
                }
                return newType;
            }

            @Override
            public CJIRType visitSelf(CJIRSelfType t, Void a) {
                return selfType;
            }
        }, null);
    }

    /**
     * Naively apply the binding. The resulting type is not checked for whether all
     * traits are properly implemented.
     *
     * @param type
     * @param marks
     * @return
     */
    CJIRType tryApply(CJIRType type, CJMark... marks) {
        return type.accept(new CJIRTypeVisitor<CJIRType, Void>() {

            @Override
            public CJIRType visitClass(CJIRClassType t, Void a) {
                var args = t.getArgs().map(arg -> arg.accept(this, a));
                return new CJIRClassType(t.getItem(), args);
            }

            @Override
            public CJIRType visitVariable(CJIRVariableType t, Void a) {
                var name = t.getName();
                var newType = map.getOrNull(name);
                if (newType == null) {
                    if (!name.endsWith("?")) {
                        name += "?";
                    }
                    return new CJIRVariableType(new CJIRTypeParameter(
                            new CJAstTypeParameter(CJMark.getBuiltin(), false, List.of(), name, List.of())),
                            List.of());
                }
                return newType;
            }

            @Override
            public CJIRType visitSelf(CJIRSelfType t, Void a) {
                return selfType;
            }
        }, null);
    }

    public int size() {
        return map.size();
    }

    @Override
    public String toString() {
        throw CJError.of("Don't use CJIRBinding.toString()");
    }

    public String getSummary() {
        var sb = new StringBuilder();
        sb.append(selfType.repr());
        for (var key : List.sorted(map.keys())) {
            sb.append("," + key + "=" + map.get(key).repr());
        }
        return sb.toString();
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CJIRBinding)) {
            return false;
        }
        var other = (CJIRBinding) obj;
        return selfType.equals(other.selfType) && map.equals(other.map);
    }

    @Override
    public int hashCode() {
        return Pair.of(selfType, map).hashCode();
    }
}
