package crossj.cj;

import crossj.base.Map;

public final class CJIRBinding {
    private final Map<String, CJIRType> map = Map.of();

    void put(String name, CJIRType newType) {
        map.put(name, newType);
    }

    /**
     * Naively apply the binding.
     * The resulting type is not checked for whether all traits are
     * properly implemented.
     * @param type
     * @param marks
     * @return
     */
    CJIRType apply(CJIRType type, CJMark... marks) {
        return type.accept(new CJIRTypeVisitor<CJIRType, Void>(){

            @Override
            public CJIRType visitClass(CJIRClassType t, Void a) {
                var args = t.getArgs().map(arg -> arg.accept(this, a));
                return new CJIRClassType(t.getItem(), args);
            }

            @Override
            public CJIRType visitVariable(CJIRVariableType t, Void a) {
                var name = t.getName();
                var newType = map.get(name);
                if (newType == null) {
                    throw CJError.of("No binding for type variable " + name + " found", marks);
                }
                return newType;
            }

            @Override
            public CJIRType visitSelf(CJIRSelfType t, Void a) {
                // TODO: Reconsider if this is the correct behavior
                return t;
            }
        }, null);
    }
}
