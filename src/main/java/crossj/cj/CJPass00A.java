package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Tuple3;

/**
 * Interfaces
 *
 * Interfaces are basically classes with fields corresponding to the interface
 * methods.
 *
 * Together with a nested trait named "Trait" that indicates that a type
 * implements this interface.
 *
 */
public final class CJPass00A {
    public static CJAstItemDefinition apply(CJAstItemDefinition item) {
        updateNestedMembersInPlace(item);
        return item.getKind() == CJIRItemKind.Interface ? handleInterface(item) : item;
    }

    private static CJAstItemDefinition handleInterface(CJAstItemDefinition oldItem) {
        var itemMark = oldItem.getMark();
        var importsCombo = oldItem.getImportsCombo().clone();
        var annotations = oldItem.getAnnotations();
        annotations.add(new CJAstAnnotationExpression(itemMark, "implicit",
                List.of(new CJAstAnnotationExpression(itemMark, "Trait", List.of()),
                        new CJAstAnnotationExpression(itemMark, "__fromTrait", List.of()))));
        var oldMembers = oldItem.getMembers();
        var newMembers = List.<CJAstItemMemberDefinition>of();
        var interfaceMethods = List.<CJAstMethodDefinition>of();
        for (var oldMember : oldMembers) {
            if (oldMember instanceof CJAstFieldDefinition) {
                throw CJError.of("Interfaces may not have field declarations", oldMember.getMark());
            } else if (oldMember instanceof CJAstCaseDefinition) {
                throw CJError.of("Interfaces may not have case declarations", oldMember.getMark());
            } else if (oldMember instanceof CJAstMethodDefinition) {
                var oldMethod = (CJAstMethodDefinition) oldMember;
                if (isInterfaceMethod(oldMethod)) {
                    interfaceMethods.add(oldMethod);
                    newMembers.add(implMethodFromInterfaceMethod(oldMethod));
                    newMembers.add(fieldFromInterfaceMethod(oldMethod));
                } else {
                    newMembers.add(oldMember);
                }
            } else {
                Assert.that(oldMember instanceof CJAstItemDefinition);
                newMembers.add(oldMember);
            }
        }
        newMembers.add(createFromTrait(oldItem, interfaceMethods));
        var synthTrait = createTrait(oldItem, interfaceMethods);
        newMembers.add(synthTrait);
        importsCombo.add(List.of(new CJAstImport(itemMark,
                synthTrait.getPackageName() + "." + synthTrait.getShortName(), Optional.empty())));
        var newItem = new CJAstItemDefinition(itemMark, oldItem.getPackageName(), importsCombo,
                oldItem.getComment(), annotations, oldItem.getModifiers(), oldItem.getKind(), oldItem.getShortName(),
                oldItem.getTypeParameters(), oldItem.getTraitDeclarations(), newMembers);
        return newItem;
    }

    private static boolean isInterfaceMethod(CJAstMethodDefinition method) {
        return method.getBody().isEmpty() && !method.getParameters().isEmpty()
                && method.getParameters().get(0).getName().equals("self") && method.getTypeParameters().isEmpty();
    }

    private static CJAstFieldDefinition fieldFromInterfaceMethod(CJAstMethodDefinition interfaceMethod) {
        var fieldName = "__im_" + interfaceMethod.getName();
        var fnType = getFnType(interfaceMethod);
        return new CJAstFieldDefinition(interfaceMethod.getMark(), Optional.empty(), // comment
                List.of(), // annotations
                List.of(), // modifiers
                false, fieldName, fnType, Optional.empty());
    }

    private static CJAstTypeExpression getFnType(CJAstMethodDefinition method) {
        var fnTypeArgs = method.getParameters().sliceFrom(1).map(p -> p.getType());
        fnTypeArgs.add(
                method.getReturnType().getOrElseDo(() -> new CJAstTypeExpression(method.getMark(), "Unit", List.of())));
        return new CJAstTypeExpression(method.getMark(), "Fn", fnTypeArgs);
    }

    private static CJAstMethodDefinition implMethodFromInterfaceMethod(CJAstMethodDefinition interfaceMethod) {
        // imethod(self, ...args): R = self.__im_imethod.call(...args)
        var selfExpr = new CJAstVariableAccess(interfaceMethod.getMark(), "self");
        var fieldExpr = new CJAstMethodCall(interfaceMethod.getMark(), Optional.empty(),
                "__get___im_" + interfaceMethod.getName(), List.of(), List.of(selfExpr));
        var args = List.<CJAstExpression>of(fieldExpr);
        for (int i = 1; i < interfaceMethod.getParameters().size(); i++) {
            args.add(new CJAstVariableAccess(interfaceMethod.getMark(),
                    interfaceMethod.getParameters().get(i).getName()));
        }
        var body = new CJAstMethodCall(interfaceMethod.getMark(), Optional.empty(), "call", List.of(), args);
        return new CJAstMethodDefinition(interfaceMethod.getMark(), interfaceMethod.getComment(),
                interfaceMethod.getAnnotations(), interfaceMethod.getConditions(), interfaceMethod.getModifiers(),
                interfaceMethod.getName(), interfaceMethod.getTypeParameters(), interfaceMethod.getParameters(),
                interfaceMethod.getReturnType(), Optional.of(body));
    }

    private static CJAstItemDefinition createTrait(CJAstItemDefinition oldItem,
            List<CJAstMethodDefinition> interfaceMethods) {
        var newPackageName = oldItem.getPackageName() + "." + oldItem.getName();
        return new CJAstItemDefinition(oldItem.getMark(), newPackageName, oldItem.getImportsCombo(), Optional.empty(),
                List.of(), List.of(), CJIRItemKind.Trait, "Trait", oldItem.getTypeParameters(), List.of(),
                interfaceMethods.map(m -> m));
    }

    /**
     * Synthesize a method "__fromTrait[T: Trait](t: T): Self" that will convert any
     * value t that implements Self.Trait into an instance of Self
     */
    private static CJAstMethodDefinition createFromTrait(CJAstItemDefinition oldItem,
            List<CJAstMethodDefinition> interfaceMethods) {
        var mark = oldItem.getMark();
        var selfType = new CJAstTypeExpression(mark, "Self", List.of());
        var tExpr = new CJAstVariableAccess(mark, "t");
        var body = new CJAstMethodCall(mark, Optional.of(selfType), "__malloc", List.of(), interfaceMethods.map(m -> {
            var params = m.getParameters().sliceFrom(1);
            var args = List.<CJAstExpression>of(tExpr);
            args.addAll(params.map(p -> new CJAstVariableAccess(p.getMark(), p.getName())));
            return new CJAstLambda(mark, false, params.map(p -> Tuple3.of(p.getMark(), false, p.getName())),
                    new CJAstMethodCall(mark, Optional.empty(), m.getName(), List.of(), args));
        }));
        return new CJAstMethodDefinition(mark, Optional.empty(), // comment
                List.of(), // annotations
                List.of(), // conditions
                List.of(), // modifiers
                "__fromTrait", List.of(new CJAstTypeParameter(mark, false, List.of(), // annotations
                        "T", List.of(new CJAstTraitExpression(mark, "Trait", List.of())))),
                List.of(new CJAstParameter(mark, false, "t", new CJAstTypeExpression(mark, "T", List.of()))),
                Optional.of(selfType), Optional.of(body));
    }

    private static void updateNestedMembersInPlace(CJAstItemDefinition item) {
        var members = item.getMembers();
        for (int i = 0; i < members.size(); i++) {
            if (members.get(i) instanceof CJAstItemDefinition) {
                members.set(i, apply((CJAstItemDefinition) members.get(i)));
            }
        }
    }
}
