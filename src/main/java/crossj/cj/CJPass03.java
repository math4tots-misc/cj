package crossj.cj;

/**
 * Pass 3
 *
 * - Checks type parameter traits and trait declarations, and <br/>
 * - Materializes methods
 */
public final class CJPass03 extends CJPassBaseEx {
    CJPass03(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        checkTypeParameterTraitsAndTraitDeclarations(item);
        materializeMethods(item);
    }

    /**
     * Creates all the CJIRMethod objects for this item.
     */
    private void materializeMethods(CJIRItem item) {
        for (var memberAst : item.getAst().getMembers()) {
            if (memberAst instanceof CJAstMethodDefinition) {
                var methodAst = (CJAstMethodDefinition) memberAst;
                var conditions = methodAst.getConditions().map(condition -> new CJIRTypeCondition(condition,
                        getTypeParameter(condition.getVariableName(), condition.getMark())));
                var typeParameters = methodAst.getTypeParameters().map(CJIRTypeParameter::new);
                var method = new CJIRMethod(methodAst, conditions, typeParameters);

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

                item.getMembers().add(method);
            } else {
                throw CJError.of("TODO: materializeMethods " + memberAst.getClass().getName(), memberAst.getMark());
            }
        }
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
