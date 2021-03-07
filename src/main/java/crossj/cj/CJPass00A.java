package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;

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
        var annotations = oldItem.getAnnotations();
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
        var newItem = new CJAstItemDefinition(oldItem.getMark(), oldItem.getPackageName(), oldItem.getImports(),
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
        var fnTypeArgs = interfaceMethod.getParameters().sliceFrom(1).map(p -> p.getType());
        fnTypeArgs.add(interfaceMethod.getReturnType()
                .getOrElseDo(() -> new CJAstTypeExpression(interfaceMethod.getMark(), "Unit", List.of())));
        var fnType = new CJAstTypeExpression(interfaceMethod.getMark(), "Fn", fnTypeArgs);
        return new CJAstFieldDefinition(interfaceMethod.getMark(), Optional.empty(), // comment
                List.of(), // annotations
                List.of(), // modifiers
                false, fieldName, fnType, Optional.empty());
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

    private static void updateNestedMembersInPlace(CJAstItemDefinition item) {
        var members = item.getMembers();
        for (int i = 0; i < members.size(); i++) {
            if (members.get(i) instanceof CJAstItemDefinition) {
                members.set(i, apply((CJAstItemDefinition) members.get(i)));
            }
        }
    }
}
