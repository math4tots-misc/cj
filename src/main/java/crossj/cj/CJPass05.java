package crossj.cj;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Range;
import crossj.base.Repr;
import crossj.base.Str;

/**
 * Pass 5
 *
 * Doesn't add anything, just performs some validations on method type
 * signatures.
 */
final class CJPass05 extends CJPassBaseEx {
    private static List<CJIRVariableType> dummyVars = List.of();

    private static List<CJIRVariableType> getDummyVars(int len) {
        while (dummyVars.size() < len) {
            var ast = new CJAstTypeParameter(CJMark.getBuiltin(), false, "$" + dummyVars.size(), List.of());
            var declaration = new CJIRTypeParameter(ast);
            dummyVars.add(new CJIRVariableType(declaration, List.of()));
        }
        return dummyVars.slice(0, len);
    }

    CJPass05(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        if (item.isTrait()) {
            if (item.isNative()) {
                throw CJError.of("Traits cannot be native", item.getMark());
            }
        } else {
            checkMethods(item);
        }
    }

    /**
     * Checks that the given item (assumed to be a class) implements all the methods
     * as declared in its traits.
     */
    private void checkMethods(CJIRItem item) {
        var mark = item.getMark();
        var type = (CJIRClassType) item.toTraitOrClassType();
        var methodMap = Map.<String, MethodEntry>of();
        addMethods(type, methodMap, type, mark);
        walkTraits(item, trait -> {
            addMethods(type, methodMap, trait, mark);
            return null;
        });
        for (var entry : methodMap.values()) {
            if (!entry.hasBody()) {
                throw CJError.of(
                        item.getFullName() + " does not implement method " + Repr.of(entry.getName())
                                + " but it is declared abstract in " + entry.getOwner().getItem().getFullName(),
                        mark, entry.getMark());
            }
        }
    }

    private static void addMethods(CJIRClassType classType, Map<String, MethodEntry> map, CJIRTraitOrClassType type,
            CJMark classMark) {
        for (var methodRef : type.getMethodRefs()) {
            var name = methodRef.getName();
            var signature = Signature.fromMethodRef(methodRef, classType);
            var entry = map.getOrNull(name);
            if (entry != null && !entry.getSignature().equals(signature)) {
                throw CJError.of(
                        "Conflicting method definitions for " + classType.getItem().getFullName() + "." + name + " ("
                                + entry.getOwner().getItem().getFullName() + " -> " + entry.getSignature() + " vs "
                                + methodRef.getOwner().getItem().getFullName() + " -> " + signature + ")",
                        entry.getMark(), methodRef.getMark());
            }
            if (entry == null || !entry.hasBody()) {
                map.put(name, new MethodEntry(methodRef.getMark(), type, name, signature,
                        type.getItem().isNative() || methodRef.getMethod().getBody().isPresent()));
            }
        }
    }

    private static final class MethodEntry {
        private final CJMark mark;
        private final CJIRTraitOrClassType owner;
        private final String name;
        private final Signature signature;
        private final boolean bodyPresent;

        MethodEntry(CJMark mark, CJIRTraitOrClassType owner, String name, Signature signature, boolean bodyPresent) {
            this.mark = mark;
            this.owner = owner;
            this.name = name;
            this.signature = signature;
            this.bodyPresent = bodyPresent;
        }

        public CJMark getMark() {
            return mark;
        }

        public CJIRTraitOrClassType getOwner() {
            return owner;
        }

        public String getName() {
            return name;
        }

        public Signature getSignature() {
            return signature;
        }

        public boolean hasBody() {
            return bodyPresent;
        }
    }

    private static CJIRBinding bindMethodWithDummyVars(CJIRMethodRef methodRef) {
        return methodRef.getBinding(getDummyVars(methodRef.getMethod().getTypeParameters().size()).map(x -> x));
    }

    private static final class Signature {
        // TODO: compare type parameter traits
        private final int typeArgc;
        private final List<CJIRType> parameterTypes;
        private final CJIRType returnType;

        static Signature fromMethodRef(CJIRMethodRef methodRef, CJIRClassType selfType) {
            var binding = bindMethodWithDummyVars(methodRef);
            var parameterTypes = methodRef.getMethod().getParameters()
                    .map(p -> substitute(p.getVariableType(), binding, selfType));
            var returnType = substitute(methodRef.getMethod().getReturnType(), binding, selfType);
            return new Signature(methodRef.getMethod().getTypeParameters().size(), parameterTypes, returnType);
        }

        private Signature(int typeArgc, List<CJIRType> parameterTypes, CJIRType returnType) {
            this.typeArgc = typeArgc;
            this.parameterTypes = parameterTypes;
            this.returnType = returnType;
        }

        @Override
        public boolean equals(Object obj) {
            if (!(obj instanceof Signature)) {
                return false;
            }
            var other = (Signature) obj;
            return typeArgc == other.typeArgc && parameterTypes.equals(other.parameterTypes)
                    && returnType.equals(other.returnType);
        }

        @Override
        public String toString() {
            return "(" + Str.join(",", Range.upto(typeArgc).map(i -> "$" + i)) + ";" + Str.join(",", parameterTypes)
                    + ";" + returnType + ")";
        }
    }

    private static CJIRType substitute(CJIRType type, CJIRBinding binding, CJIRClassType selfType) {
        return type.accept(new CJIRTypeVisitor<CJIRType, Void>() {

            @Override
            public CJIRType visitClass(CJIRClassType t, Void a) {
                var args = t.getArgs().map(arg -> substitute(arg, binding, selfType));
                return new CJIRClassType(t.getItem(), args);
            }

            @Override
            public CJIRType visitVariable(CJIRVariableType t, Void a) {
                return binding.getMap().get(t.getName());
            }

            @Override
            public CJIRType visitSelf(CJIRSelfType t, Void a) {
                return selfType;
            }
        }, null);
    }
}
