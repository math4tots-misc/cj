package crossj.cj;

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
        for (var memberAst : item.getAst().getMembers()) {
            if (memberAst instanceof CJAstMethodDefinition) {
                materializeMethod(item, (CJAstMethodDefinition) memberAst, false);
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

    private CJAstMethodDefinition synthesizeCaseMethod(CJIRItem item, CJAstCaseDefinition caseAst) {
        var parameters = Range.upto(caseAst.getTypes().size()).map(i -> new CJAstParameter(
            caseAst.getTypes().get(i).getMark(),
            false,
            "a" + i,
            caseAst.getTypes().get(i)
        )).list();
        return new CJAstMethodDefinition(
            caseAst.getMark(),
            List.of(),
            List.of(),
            caseAst.getName(),
            List.of(),
            parameters,
            Optional.of(new CJAstTypeExpression(caseAst.getMark(), "Self", List.of())),
            Optional.empty());
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
