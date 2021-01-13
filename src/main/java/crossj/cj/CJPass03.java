package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Range;

/**
 * Pass 3
 *
 * - Checks type parameter traits and trait declarations, and <br/>
 * - Materializes methods
 */
final class CJPass03 extends CJPassBaseEx {
    CJPass03(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        checkTypeParameterTraitsAndTraitDeclarations(item);
        materializeMembers(item);
    }

    /**
     * Creates all the CJIRMethod objects for this item.
     */
    private void materializeMembers(CJIRItem item) {

        if (item.getKind() == CJIRItemKind.Class) {
            var mallocMethodAst = synthesizeMallocMethod(item);
            materializeMethod(item, mallocMethodAst, true, null);
        }

        for (var memberAst : item.getAst().getMembers()) {
            if (memberAst instanceof CJAstMethodDefinition) {
                materializeMethod(item, (CJAstMethodDefinition) memberAst, false, null);
            } else if (memberAst instanceof CJAstFieldDefinition) {
                var fieldAst = (CJAstFieldDefinition) memberAst;
                if (fieldAst.isStatic()) {
                    if (item.getTypeParameters().size() > 0) {
                        throw CJError.of("classes with type parameters cannot have static fields", fieldAst.getMark());
                    }
                    if (fieldAst.getExpression().isEmpty()) {
                        throw CJError.of("static fields must always have an initializer", fieldAst.getMark());
                    }
                } else {
                    if (item.getKind() != CJIRItemKind.Class) {
                        throw CJError.of("unions and traits cannot have non-static fields", fieldAst.getMark());
                    }
                    if (fieldAst.getExpression().isPresent()) {
                        throw CJError.of("non-static fields may not have an initializer", fieldAst.getMark());
                    }
                }
                var index = fieldAst.isStatic() ? -1 : item.getFields().filter(f -> !f.isStatic()).size();
                var type = lctx.evalTypeExpression(fieldAst.getType());
                var field = new CJIRField(fieldAst, index, type);
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
                materializeMethod(item, methodAst, true, null);
            } else if (memberAst instanceof CJAstItemDefinition) {
                // item definitions are currently already pulled to the top level
            } else {
                throw CJError.of("TODO: materializeMembers " + memberAst.getClass().getName(), memberAst.getMark());
            }
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
        return synthesizeMethod(mark, methodName, parameters, returnType);
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
        return synthesizeMethod(mark, methodName, parameters, returnType);
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
        return synthesizeMethod(mark, methodName, parameters, returnType);
    }

    private CJAstMethodDefinition synthesizeMallocMethod(CJIRItem item) {
        var fields = item.getAst().getMembers().filter(f -> !f.isStatic() && f instanceof CJAstFieldDefinition)
                .map(f -> (CJAstFieldDefinition) f);
        Assert.that(fields.all(f -> !f.isStatic()));
        var mark = item.getMark();
        var methodName = "__malloc";
        var parameters = fields.map(f -> new CJAstParameter(f.getMark(), false, f.getName(), f.getType()));
        var returnType = newSelfTypeExpression(item.getMark());
        return synthesizeMethod(mark, methodName, parameters, returnType);
    }

    private CJAstMethodDefinition synthesizeCaseMethod(CJIRItem item, CJAstCaseDefinition caseAst) {
        var mark = caseAst.getMark();
        var parameters = Range.upto(caseAst.getTypes().size()).map(
                i -> new CJAstParameter(caseAst.getTypes().get(i).getMark(), false, "a" + i, caseAst.getTypes().get(i)))
                .list();
        return synthesizeMethod(mark, caseAst.getName(), parameters, newSelfTypeExpression(mark));
    }

    private CJAstMethodDefinition synthesizeMethod(CJMark mark, String name, List<CJAstParameter> parameters,
            CJAstTypeExpression returnType) {
        return new CJAstMethodDefinition(mark, Optional.empty(), List.of(), List.of(), List.of(), name, List.of(),
                parameters, Optional.of(returnType), Optional.empty());
    }

    private CJAstTypeExpression newSelfTypeExpression(CJMark mark) {
        return new CJAstTypeExpression(mark, "Self", List.of());
    }

    private CJAstTypeExpression newUnitTypeExpression(CJMark mark) {
        return new CJAstTypeExpression(mark, "Unit", List.of());
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
        var typeParameters = methodAst.getTypeParameters().map(CJIRTypeParameter::new);
        if (annotationProcessor.isGeneric() && item.isTrait()) {
            throw CJError.of("Trait methods cannot be marked generic", methodAst.getMark());
        }
        var method = new CJIRMethod(methodAst, conditions, typeParameters,
                implPresent || methodAst.getBody().isPresent() || item.isNative(), annotationProcessor.isTest(),
                annotationProcessor.isGeneric(), extra);

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
            traitAsts.addAll(synthesizeTypeVariableAutoTraits(typeParameterAst));
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
