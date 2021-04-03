package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;
import crossj.base.Pair;
import crossj.base.Range;
import crossj.base.Tuple3;
import crossj.base.Tuple4;

/**
 * Pass 3
 *
 * - Process implicit declarations - Checks type parameter traits and trait
 * declarations, and <br/>
 * - Materializes methods
 *
 * Derived methods are also synthesized here
 */
final class CJPass03 extends CJPassBaseEx {
    CJPass03(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        processImplicitDeclarations(item);
        checkTypeParameterTraitsAndTraitDeclarations(item);
        materializeMembers(item);
    }

    private void processImplicitDeclarations(CJIRItem item) {
        processTraitItemForImplicitDeclarations(item, item);
        CJIRContextBase.walkTraitItems(item, traitItem -> {
            processTraitItemForImplicitDeclarations(item, traitItem);
            return null;
        });
    }

    private void processTraitItemForImplicitDeclarations(CJIRItem item, CJIRItem traitItem) {
        var implicitsTraitsList = item.getImplicitsTraitsList();
        var implicitsTypeMap = item.getImplicitsTypeItemMap();
        var seen = Map.<CJIRItem, CJIRItem>of();
        for (var pair : traitItem.getUnprocessedImplicits()) {
            var refItemFullName = CJIRLocalContext.getFullItemNameWithMap(traitItem.getShortNameMap(), pair.get1(),
                    item.getMark());
            var refItem = ctx.loadItem(refItemFullName, item.getMark());
            if (seen.containsKey(refItem)) {
                // Duplicates, even through inheritance are not allowed.
                // Rather than worry about proper conflict resolution mechanisms, for now
                // I'm forbidding any scenario in which there are potentially more than one
                // method for converting from A -> B
                throw CJError.of("Conflicting @implicit annotations", item.getMark(), seen.get(refItem).getMark(),
                        traitItem.getMark());
            }
            seen.put(refItem, traitItem);
            var methodName = pair.get2();
            if (refItem.isTrait()) {
                implicitsTraitsList.add(Pair.of(refItem, methodName));
            } else {
                implicitsTypeMap.put(refItem, methodName);
            }
        }
    }

    /**
     * Creates all the CJIRMethod objects for this item.
     */
    private void materializeMembers(CJIRItem item) {

        for (var memberAst : item.getAst().getMembers()) {
            if (memberAst instanceof CJAstMethodDefinition) {
                materializeMethod(item, (CJAstMethodDefinition) memberAst, false, null);
            } else if (memberAst instanceof CJAstFieldDefinition) {
                var fieldAst = (CJAstFieldDefinition) memberAst;
                if (item.getKind() == CJIRItemKind.Trait) {
                    throw CJError.of("Traits cannot have fields", fieldAst.getMark());
                }
                if (fieldAst.isStatic()) {
                    if (item.getTypeParameters().size() > 0) {
                        throw CJError.of("classes with type parameters cannot have static fields", fieldAst.getMark());
                    }
                } else {
                    if (item.getKind() != CJIRItemKind.Class) {
                        throw CJError.of("unions cannot have non-static fields", fieldAst.getMark());
                    }
                }
                var index = fieldAst.isStatic() ? -1 : item.getFields().filter(f -> !f.isStatic()).size();
                var type = lctx.evalTypeExpression(fieldAst.getType());
                fieldAst.getAnnotations();
                var annotations = CJIRAnnotationProcessor.processMember(fieldAst);
                var field = new CJIRField(fieldAst, annotations, index, type);
                if (field.isLateinit() && !field.isMutable()) {
                    throw CJError.of("lateinit fields must be mutable", field.getMark());
                }
                if (field.isLateinit() && fieldAst.getExpression().isPresent()) {
                    throw CJError.of("lateinit fields cannot be initialized", field.getMark());
                }
                if (!field.isLateinit() && fieldAst.isStatic() && fieldAst.getExpression().isEmpty()) {
                    if (fieldAst.getExpression().isEmpty()) {
                        throw CJError.of("static fields must always have an initializer", fieldAst.getMark());
                    }
                }
                item.getFields().add(field);
                var accessMethodAst = synthesizeFieldAccessMethod(item, fieldAst);
                materializeMethod(item, accessMethodAst, true, new CJIRFieldMethodInfo(field, ""));
                if (field.isMutable()) {
                    var assignMethodAst = synthesizeFieldAssignmentMethod(item, fieldAst);
                    materializeMethod(item, assignMethodAst, true, new CJIRFieldMethodInfo(field, "="));
                    if (field.getType().equals(ctx.getIntType())) {
                        var augMethodAst = synthesizeFieldAugMethod(item, fieldAst);
                        materializeMethod(item, augMethodAst, true, new CJIRFieldMethodInfo(field, "+="));
                    }
                }
            } else if (memberAst instanceof CJAstCaseDefinition) {
                if (item.getKind() != CJIRItemKind.Union) {
                    throw CJError.of("Only union items may have case definitions", memberAst.getMark());
                }
                var tag = item.getCases().size();
                var caseAst = (CJAstCaseDefinition) memberAst;
                var types = caseAst.getTypes().map(lctx::evalTypeExpression);
                var caseDefn = new CJIRCase(caseAst, tag, types);
                item.getCases().add(caseDefn);
                var methodAst = synthesizeCaseMethod(item, caseAst);
                materializeMethod(item, methodAst, true, new CJIRCaseMethodInfo(caseDefn));
                if (caseAst.getTypes().isEmpty()) {
                    var caseMethodAst = synthesizeEmptyCaseMethod(item, caseAst);
                    materializeMethod(item, caseMethodAst, false, null);
                }
            } else if (memberAst instanceof CJAstItemDefinition) {
                // item definitions are currently already pulled to the top level
            } else {
                throw CJError.of("TODO: materializeMembers " + memberAst.getClass().getName(), memberAst.getMark());
            }
        }

        if (item.getKind() == CJIRItemKind.Class && !item.isNative()) {
            var mallocMethodAst = synthesizeMallocMethod(item);
            materializeMethod(item, mallocMethodAst, true, null);
        }

        if (item.getKind() == CJIRItemKind.Class && !item.isNative()
                && !item.getMethods().any(m -> m.getName().equals("__new"))) {
            deriveItemClassCheck(item, "__new");
            var methodAst = synthesizeNewMethod(item);
            materializeMethod(item, methodAst, true, null);
        }
        if (item.isDeriveEq()) {
            deriveItemClassCheck(item, "eq");
            var methodAst = synthesizeEqMethod(item);
            materializeMethod(item, methodAst, true, null);
        }
        if (item.isDeriveHash()) {
            deriveItemClassCheck(item, "hash");
            var methodAst = synthesizeHashMethod(item);
            materializeMethod(item, methodAst, true, null);
        }
        if (item.isDeriveRepr()) {
            deriveItemClassOrUnionCheck(item, "repr");
            var methodAst = synthesizeReprMethod(item);
            materializeMethod(item, methodAst, true, null);
        }
        if (item.isDeriveDefault()) {
            deriveItemClassCheck(item, "default");
            var methodAst = synthesizeDefaultMethod(item);
            materializeMethod(item, methodAst, true, null);
        }
    }

    private static void deriveItemClassCheck(CJIRItem item, String name) {
        if (item.getKind() != CJIRItemKind.Class) {
            throw CJError.of("derive(" + name + ") can only be applied to class items", item.getMark());
        }
    }

    private static void deriveItemClassOrUnionCheck(CJIRItem item, String name) {
        if (item.getKind() != CJIRItemKind.Class && item.getKind() != CJIRItemKind.Union) {
            throw CJError.of("derive(" + name + ") can only be applied to class items", item.getMark());
        }
    }

    private CJAstMethodDefinition synthesizeFieldAccessMethod(CJIRItem item, CJAstFieldDefinition fieldAst) {
        var mark = fieldAst.getMark();
        var methodName = fieldAst.getGetterName();
        var parameters = List.<CJAstParameter>of();
        if (!fieldAst.isStatic()) {
            parameters.add(new CJAstParameter(mark, false, "self", newSelfTypeExpression(mark)));
        }
        var returnType = fieldAst.getType();
        var method = synthesizeGenericMethod(mark, methodName, parameters, returnType);
        if (fieldAst.isPrivate()) {
            method.getModifiers().add(CJIRModifier.Private);
        }
        return method;
    }

    private CJAstMethodDefinition synthesizeFieldAssignmentMethod(CJIRItem item, CJAstFieldDefinition fieldAst) {
        var mark = fieldAst.getMark();
        var methodName = fieldAst.getSetterName();
        var parameters = List.<CJAstParameter>of();
        if (!fieldAst.isStatic()) {
            parameters.add(new CJAstParameter(mark, false, "self", newSelfTypeExpression(mark)));
        }
        parameters.add(new CJAstParameter(mark, false, "value", fieldAst.getType()));
        var returnType = newUnitTypeExpression(mark);
        var method = synthesizeGenericMethod(mark, methodName, parameters, returnType);
        if (fieldAst.isPrivate()) {
            method.getModifiers().add(CJIRModifier.Private);
        }
        return method;
    }

    private CJAstMethodDefinition synthesizeFieldAugMethod(CJIRItem item, CJAstFieldDefinition fieldAst) {
        var mark = fieldAst.getMark();
        var methodName = "__augadd_" + fieldAst.getName();
        var parameters = List.<CJAstParameter>of();
        if (!fieldAst.isStatic()) {
            parameters.add(new CJAstParameter(mark, false, "self", newSelfTypeExpression(mark)));
        }
        parameters.add(new CJAstParameter(mark, false, "value", fieldAst.getType()));
        var returnType = newUnitTypeExpression(mark);
        return synthesizeGenericMethod(mark, methodName, parameters, returnType);
    }

    private CJAstMethodDefinition synthesizeMallocMethod(CJIRItem item) {
        var nonStaticFields = item.getFields().filter(f -> !f.isStatic());
        var argFields = nonStaticFields.filter(f -> f.includeInMalloc());
        var mark = item.getMark();
        var methodName = "__malloc";
        var parameters = argFields.map(f -> f.getAst())
                .map(f -> new CJAstParameter(f.getMark(), false, f.getName(), f.getType()));
        var returnType = newSelfTypeExpression(item.getMark());
        return synthesizeGenericMethod(mark, methodName, parameters, returnType);
    }

    private CJAstMethodDefinition synthesizeCaseMethod(CJIRItem item, CJAstCaseDefinition caseAst) {
        var mark = caseAst.getMark();
        var parameters = Range.upto(caseAst.getTypes().size()).map(
                i -> new CJAstParameter(caseAst.getTypes().get(i).getMark(), false, "a" + i, caseAst.getTypes().get(i)))
                .list();
        return synthesizeGenericMethod(mark, caseAst.getName(), parameters, newSelfTypeExpression(mark));
    }

    private CJAstMethodDefinition synthesizeEmptyCaseMethod(CJIRItem item, CJAstCaseDefinition caseAst) {
        Assert.that(caseAst.getTypes().isEmpty());
        var name = caseAst.getName();
        var mark = caseAst.getMark();
        var body = new CJAstMethodCall(mark, Optional.of(new CJAstTypeExpression(mark, "Self", List.of())), name,
                List.of(), List.of());
        return synthesizeGenericMethodWithBody(mark, "__get_" + name, List.of(), newSelfTypeExpression(mark), body);
    }

    private CJAstMethodDefinition synthesizeNewMethod(CJIRItem item) {
        var mark = item.getMark();
        var fields = item.getFields().filter(f -> f.includeInMalloc());
        var parameters = fields.map(f -> new CJAstParameter(f.getMark(), false, f.getName(), f.getAst().getType()));
        var selfType = newSelfTypeExpression(item.getMark());
        var argexprs = fields.map(f -> newGetVar(f.getMark(), f.getName()));
        var body = new CJAstMethodCall(mark, Optional.of(selfType), "__malloc", List.of(), argexprs);
        return synthesizeGenericMethodWithBody(mark, "__new", parameters, selfType, body);
    }

    private CJAstMethodDefinition synthesizeDefaultMethod(CJIRItem item) {
        var mark = item.getMark();
        var fields = item.getFields().filter(f -> f.includeInMalloc());
        var selfType = newSelfTypeExpression(item.getMark());
        var argexprs = fields.map(f -> (CJAstExpression) new CJAstMethodCall(f.getMark(),
                Optional.of(f.getAst().getType()), "default", List.of(), List.of()));
        var body = new CJAstMethodCall(mark, Optional.of(selfType), "__malloc", List.of(), argexprs);
        return synthesizeGenericMethodWithBody(mark, "default", List.of(), selfType, body);
    }

    private CJAstMethodDefinition synthesizeEqMethod(CJIRItem item) {
        var mark = item.getMark();
        var fields = item.getAst().getMembers().filter(f -> !f.isStatic() && f instanceof CJAstFieldDefinition)
                .map(f -> (CJAstFieldDefinition) f);
        var boolType = newSimpleTypeWithName(mark, "Bool");
        var selfType = newSelfTypeExpression(mark);
        var parameters = List.of(new CJAstParameter(mark, false, "self", selfType),
                new CJAstParameter(mark, false, "other", selfType));
        var selfExpr = newGetVar(mark, "self");
        var otherExpr = newGetVar(mark, "other");
        var body = fields.map(f -> newMethodCall(mark, "__eq", List.of(newGetField(selfExpr, f.getName()),
                newMethodCall(mark, f.getGetterName(), List.of(otherExpr))))).reduce(this::newAnd);
        return synthesizeMethodWithBody(mark, "__eq", parameters, boolType, body);
    }

    private CJAstMethodDefinition synthesizeHashMethod(CJIRItem item) {
        var mark = item.getMark();
        var fields = item.getAst().getMembers().filter(f -> !f.isStatic() && f instanceof CJAstFieldDefinition)
                .map(f -> (CJAstFieldDefinition) f);
        var intType = newSimpleTypeWithName(mark, "Int");
        var selfType = newSelfTypeExpression(mark);
        var parameters = List.of(new CJAstParameter(mark, false, "self", selfType));
        var selfExpr = newGetVar(mark, "self");
        var listExpr = newList(mark, fields.map(
                f -> newMethodCall(mark, "hash", List.of(newMethodCall(mark, f.getGetterName(), List.of(selfExpr))))));
        var body = newMethodCall(mark, "hash", List.of(listExpr));
        return synthesizeMethodWithBody(mark, "hash", parameters, intType, body);
    }

    private CJAstMethodDefinition synthesizeReprMethod(CJIRItem item) {
        switch (item.getKind()) {
        case Class:
            return synthesizeClassReprMethod(item);
        case Union:
            return synthesizeUnionReprMethod(item);
        default:
            throw CJError.of("dreive(repr) not supported for item kind: " + item.getKind(), item.getMark());
        }
    }

    private CJAstMethodDefinition synthesizeClassReprMethod(CJIRItem item) {
        var mark = item.getMark();
        var fields = item.getAst().getMembers().filter(f -> !f.isStatic() && f instanceof CJAstFieldDefinition)
                .map(f -> (CJAstFieldDefinition) f);
        var stringType = newSimpleTypeWithName(mark, "String");
        var selfType = newSelfTypeExpression(mark);
        var parameters = List.of(new CJAstParameter(mark, false, "self", selfType));
        var selfExpr = newGetVar(mark, "self");
        var inner = newMethodCall(mark, "join",
                List.of(newString(mark, ", "), newList(mark, fields.map(f -> newMethodCall(mark, "repr",
                        List.of(newMethodCall(mark, f.getGetterName(), List.of(selfExpr))))))));
        var body = newAdd(newString(mark, item.getShortName() + "("), newAdd(inner, newString(mark, ")")));
        return synthesizeMethodWithBody(mark, "repr", parameters, stringType, body);
    }

    private CJAstMethodDefinition synthesizeUnionReprMethod(CJIRItem item) {
        var mark = item.getMark();
        var cases = item.getAst().getMembers().filter(c -> c instanceof CJAstCaseDefinition)
                .map(c -> (CJAstCaseDefinition) c);
        var stringType = newSimpleTypeWithName(mark, "String");
        var selfType = newSelfTypeExpression(mark);
        var parameters = List.of(new CJAstParameter(mark, false, "self", selfType));
        var selfExpr = newGetVar(mark, "self");
        var body = new CJAstWhen(mark, selfExpr, cases.map(c -> Pair.of(
                List.of(Tuple4.of(mark, c.getName(),
                        Range.upto(c.getTypes().size())
                                .map(i -> Tuple3.<CJMark, Boolean, String>of(mark, false, "a" + i)).list(),
                        false)),
                newAddList(List.of(newString(mark, item.getShortName() + "." + c.getName() + "("),
                        newJoin(mark, ", ",
                                Range.upto(c.getTypes().size()).map(i -> newRepr(newGetVar(mark, "a" + i))).list()),
                        newString(mark, ")"))))),
                List.of(), Optional.empty());
        return synthesizeMethodWithBody(mark, "repr", parameters, stringType, body);
    }

    private CJAstAnnotationExpression synthesizeGenericAnnotation(CJMark mark) {
        return new CJAstAnnotationExpression(mark, "generic", List.of());
    }

    private CJAstMethodDefinition synthesizeGenericMethodEx(CJMark mark, String name, List<CJAstParameter> parameters,
            CJAstTypeExpression returnType, Optional<CJAstExpression> body) {
        return new CJAstMethodDefinition(mark, Optional.empty(), List.of(synthesizeGenericAnnotation(mark)), List.of(),
                List.of(), name, List.of(), parameters, Optional.of(returnType), body);
    }

    private CJAstMethodDefinition synthesizeGenericMethod(CJMark mark, String name, List<CJAstParameter> parameters,
            CJAstTypeExpression returnType) {
        return synthesizeGenericMethodEx(mark, name, parameters, returnType, Optional.empty());
    }

    private CJAstMethodDefinition synthesizeGenericMethodWithBody(CJMark mark, String name,
            List<CJAstParameter> parameters, CJAstTypeExpression returnType, CJAstExpression body) {
        return synthesizeGenericMethodEx(mark, name, parameters, returnType, Optional.of(body));
    }

    private CJAstMethodDefinition synthesizeMethodWithBody(CJMark mark, String name, List<CJAstParameter> parameters,
            CJAstTypeExpression returnType, CJAstExpression body) {
        return new CJAstMethodDefinition(mark, Optional.empty(), List.of(), List.of(), List.of(), name, List.of(),
                parameters, Optional.of(returnType), Optional.of(body));
    }

    private CJAstExpression newString(CJMark mark, String text) {
        return new CJAstLiteral(mark, CJIRLiteralKind.String, "\"" + text + "\"");
    }

    private CJAstExpression newAnd(CJAstExpression left, CJAstExpression right) {
        return new CJAstLogicalBinop(left.getMark(), true, left, right);
    }

    private CJAstExpression newJoin(CJMark mark, String sep, List<CJAstExpression> args) {
        if (args.isEmpty()) {
            return newString(mark, "");
        } else {
            return newMethodCall(mark, "join", List.of(newString(mark, sep), newList(mark, args)));
        }
    }

    private CJAstExpression newGetField(CJAstExpression owner, String name) {
        return newMethodCall(owner.getMark(), "__get_" + name, List.of(owner));
    }

    private CJAstExpression newRepr(CJAstExpression e) {
        return newMethodCall(e.getMark(), "repr", List.of(e));
    }

    private CJAstExpression newAdd(CJAstExpression left, CJAstExpression right) {
        return newMethodCall(left.getMark(), "__add", List.of(left, right));
    }

    private CJAstExpression newAddList(List<CJAstExpression> exprs) {
        var e = exprs.get(0);
        for (var rhs : exprs.sliceFrom(1)) {
            e = newAdd(e, rhs);
        }
        return e;
    }

    private CJAstExpression newGetVar(CJMark mark, String name) {
        return new CJAstVariableAccess(mark, name);
    }

    private CJAstExpression newList(CJMark mark, List<CJAstExpression> args) {
        return new CJAstListDisplay(mark, args);
    }

    private CJAstExpression newMethodCall(CJMark mark, String name, List<CJAstExpression> args) {
        return new CJAstMethodCall(mark, Optional.empty(), name, List.of(), args);
    }

    private CJAstTypeExpression newSelfTypeExpression(CJMark mark) {
        return newSimpleTypeWithName(mark, "Self");
    }

    private CJAstTypeExpression newUnitTypeExpression(CJMark mark) {
        return newSimpleTypeWithName(mark, "Unit");
    }

    private CJAstTypeExpression newSimpleTypeWithName(CJMark mark, String name) {
        return new CJAstTypeExpression(mark, name, List.of());
    }

    private void materializeMethod(CJIRItem item, CJAstMethodDefinition methodAst, boolean implPresent,
            CJIRExtraMethodInfo extra) {
        var annotationProcessor = CJIRAnnotationProcessor.processMember(methodAst);
        var conditions = methodAst.getConditions().map(conditionAst -> {
            var condition = new CJIRTypeCondition(conditionAst,
                    getTypeParameter(conditionAst.getVariableName(), conditionAst.getMark()));
            for (var traitAst : conditionAst.getTraits()) {
                condition.getTraits().add(lctx.evalTraitExpression(traitAst));
            }
            return condition;
        });
        for (var typeParameter : methodAst.getTypeParameters()) {
            var itemTypeParameter = item.getTypeParameterMap().getOrNull(typeParameter.getName());
            if (itemTypeParameter != null) {
                throw CJError.of("Conflicting type variable name " + typeParameter.getName(), typeParameter.getMark(),
                        itemTypeParameter.getMark());
            }
        }
        var typeParameters = methodAst.getTypeParameters().map(CJIRTypeParameter::new);
        if (annotationProcessor.isGeneric() && item.isTrait()) {
            throw CJError.of("Trait methods cannot be marked generic", methodAst.getMark());
        }
        var method = new CJIRMethod(methodAst, conditions, typeParameters,
                implPresent || methodAst.getBody().isPresent() || item.isNative(), annotationProcessor, extra);

        if (method.isTest()) {
            if (methodAst.getTypeParameters().size() > 0 || methodAst.getParameters().size() > 0) {
                throw CJError.of("test methods may not have any kind of parameters", method.getMark());
            }
            if (item.getTypeParameters().size() > 0) {
                throw CJError.of("items with type parameters may not have test methods", method.getMark());
            }
        }

        enterMethod(method);

        for (var typeParameter : typeParameters) {
            var typeParameterAst = typeParameter.getAst();
            var traitAsts = List.<CJAstTraitExpression>of();
            traitAsts.addAll(typeParameterAst.getTraits());
            traitAsts.addAll(synthesizeTypeVariableAutoTraits(typeParameter));
            typeParameter.getTraits().addAll(traitAsts.map(lctx::evalTraitExpression));
        }

        var parameters = method.getParameters();
        for (var parameterAst : methodAst.getParameters()) {
            var type = lctx.evalTypeExpression(parameterAst.getType());
            var parameter = new CJIRParameter(parameterAst, type);
            parameters.add(parameter);
        }

        var returnType = methodAst.getReturnType().map(lctx::evalTypeExpression).getOrElseDo(lctx::getUnitType);
        method.setReturnType(returnType);

        if (method.isAsync() && !returnType.isPromiseType()) {
            throw CJError.of("Async methods must return a Promise type", method.getMark());
        }

        if (method.isVariadic() && (parameters.isEmpty() || !parameters.last().getVariableType().isListType())) {
            throw CJError.of("Variadic the last parameter of a variadic method must always be a list type",
                    method.getMark());
        }

        exitMethod();

        item.getMethods().add(method);
    }

    private CJIRTypeParameter getTypeParameter(String shortName, CJMark... marks) {
        var typeParameter = lctx.getItem().getTypeParameterMap().getOrNull(shortName);
        if (typeParameter == null && lctx.getMethod().isPresent()) {
            typeParameter = lctx.getMethod().get().getTypeParameterMap().getOrNull(shortName);
        }
        if (typeParameter == null) {
            throw CJError.of(shortName + " is not a variable", marks);
        }
        return typeParameter;
    }

    /**
     * Just checks type argument trait requirements are met. Does not add any new
     * info.
     */
    private void checkTypeParameterTraitsAndTraitDeclarations(CJIRItem item) {
        for (var typeParameter : item.getTypeParameters()) {
            var mark = typeParameter.getMark();
            for (var trait : typeParameter.getTraits()) {
                ctx.checkTrait(trait, mark);
            }
        }
        for (var traitDeclaration : item.getTraitDeclarations()) {
            for (var condition : traitDeclaration.getConditions()) {
                var mark = condition.getMark();
                for (var trait : condition.getTraits()) {
                    ctx.checkTrait(trait, mark);
                }
            }
        }
    }
}
