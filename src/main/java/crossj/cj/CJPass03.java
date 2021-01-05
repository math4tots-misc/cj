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
            materializeMethod(item, mallocMethodAst, true);
        }

        for (var memberAst : item.getAst().getMembers()) {
            if (memberAst instanceof CJAstMethodDefinition) {
                materializeMethod(item, (CJAstMethodDefinition) memberAst, false);
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
                materializeMethod(item, accessMethodAst, true);
                if (field.isMutable()) {
                    var assignMethodAst = synthesizeFieldAssignmentMethod(item, fieldAst);
                    materializeMethod(item, assignMethodAst, true);
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
                materializeMethod(item, methodAst, true);
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
        var returnType = Optional.of(fieldAst.getType());
        return new CJAstMethodDefinition(mark, List.of(), List.of(), methodName, List.of(), parameters, returnType,
                Optional.empty());
    }

    private CJAstMethodDefinition synthesizeFieldAssignmentMethod(CJIRItem item, CJAstFieldDefinition fieldAst) {
        var mark = fieldAst.getMark();
        var methodName = fieldAst.getSetterName();
        var parameters = List.<CJAstParameter>of();
        if (!fieldAst.isStatic()) {
            parameters.add(new CJAstParameter(mark, false, "self", newSelfTypeExpression(mark)));
        }
        parameters.add(new CJAstParameter(mark, false, "value", fieldAst.getType()));
        var returnType = Optional.of(newUnitTypeExpression(mark));
        return new CJAstMethodDefinition(mark, List.of(), List.of(), methodName, List.of(), parameters, returnType,
                Optional.empty());
    }

    private CJAstMethodDefinition synthesizeMallocMethod(CJIRItem item) {
        var fields = item.getAst().getMembers().filter(f -> !f.isStatic() && f instanceof CJAstFieldDefinition)
                .map(f -> (CJAstFieldDefinition) f);
        Assert.that(fields.all(f -> !f.isStatic()));
        var mark = item.getMark();
        var methodName = "__malloc";
        var parameters = fields.map(f -> new CJAstParameter(f.getMark(), false, f.getName(), f.getType()));
        var returnType = Optional.of(newSelfTypeExpression(item.getMark()));
        return new CJAstMethodDefinition(mark, List.of(), List.of(), methodName, List.of(), parameters, returnType,
                Optional.empty());
    }

    private CJAstMethodDefinition synthesizeCaseMethod(CJIRItem item, CJAstCaseDefinition caseAst) {
        var parameters = Range.upto(caseAst.getTypes().size()).map(
                i -> new CJAstParameter(caseAst.getTypes().get(i).getMark(), false, "a" + i, caseAst.getTypes().get(i)))
                .list();
        return new CJAstMethodDefinition(caseAst.getMark(), List.of(), List.of(), caseAst.getName(), List.of(),
                parameters, Optional.of(newSelfTypeExpression(caseAst.getMark())), Optional.empty());
    }

    private CJAstTypeExpression newSelfTypeExpression(CJMark mark) {
        return new CJAstTypeExpression(mark, "Self", List.of());
    }

    private CJAstTypeExpression newUnitTypeExpression(CJMark mark) {
        return new CJAstTypeExpression(mark, "Unit", List.of());
    }

    private void materializeMethod(CJIRItem item, CJAstMethodDefinition methodAst, boolean implPresent) {
        var conditions = methodAst.getConditions().map(condition -> new CJIRTypeCondition(condition,
                getTypeParameter(condition.getVariableName(), condition.getMark())));
        var typeParameters = methodAst.getTypeParameters().map(CJIRTypeParameter::new);
        var method = new CJIRMethod(methodAst, conditions, typeParameters,
                implPresent || methodAst.getBody().isPresent() || item.isNative());

        enterMethod(method);

        for (var typeParameter : typeParameters) {
            var typeParameterAst = typeParameter.getAst();
            typeParameter.getTraits().addAll(typeParameterAst.getTraits().map(lctx::evalTraitExpression));
        }

        var parameters = method.getParameters();
        for (var parameterAst : methodAst.getParameters()) {
            var type = lctx.evalTypeExpression(parameterAst.getType());
            var parameter = new CJIRParameter(parameterAst, type);
            parameters.add(parameter);
        }

        var returnType = methodAst.getReturnType().map(lctx::evalTypeExpression).getOrElseDo(lctx::getUnitType);
        method.setReturnType(returnType);

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