package crossj.cj;

import crossj.base.List;

/**
 * Pass 2
 *
 * Create the type parameter's traits and item's trait declaration IRs
 *
 * Trait constraints are checked in pass 3
 */
final class CJPass02 extends CJPassBase {
    CJPass02(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        for (var typeParameter : item.getTypeParameters()) {
            var typeParameterAst = typeParameter.getAst();
            var traitAsts = List.<CJAstTraitExpression>of();
            traitAsts.addAll(typeParameterAst.getTraits());
            traitAsts.addAll(synthesizeTypeVariableAutoTraits(typeParameterAst));
            for (var traitAst : traitAsts) {
                var trait = evalTraitExpression(traitAst);
                typeParameter.getTraits().add(trait);
            }
        }
        var traitDeclarationAsts = List.<CJAstTraitDeclaration>of();
        traitDeclarationAsts.addAll(item.getAst().getTraitDeclarations());
        if (!item.isTrait() && !item.isNullable()) {
            // unless the class/union is explicitly marked nullable, NonNull is implied
            var mark = item.getMark();
            var traitDeclarationAst = new CJAstTraitDeclaration(mark,
                    new CJAstTraitExpression(mark, "NonNull", List.of()), List.of());
            traitDeclarationAsts.add(traitDeclarationAst);
        }
        for (var traitDeclarationAst : traitDeclarationAsts) {
            var trait = evalTraitExpression(traitDeclarationAst.getTrait());
            var traitDeclaration = new CJIRTraitDeclaration(traitDeclarationAst, trait);
            for (var conditionAst : traitDeclarationAst.getConditions()) {
                var typeParameter = getVariable(conditionAst.getVariableName(), conditionAst.getMark());
                var condition = new CJIRTypeCondition(conditionAst, typeParameter);
                for (var conditionTraitAst : conditionAst.getTraits()) {
                    condition.getTraits().add(evalTraitExpression(conditionTraitAst));
                }
                traitDeclaration.getConditions().add(condition);
            }
            item.getTraitDeclarations().add(traitDeclaration);
        }
    }

    private CJIRTrait evalTraitExpression(CJAstTraitExpression texpr) {
        var traitItem = lctx.getTraitItem(texpr.getName(), texpr.getMark());
        var args = texpr.getArgs().map(te -> evalTypeExpression(te));
        checkArgc(texpr.getMark(), traitItem, args);
        return new CJIRTrait(traitItem, args);
    }

    private CJIRType evalTypeExpression(CJAstTypeExpression texpr) {
        var typeParameter = lctx.getItem().getTypeParameterMap().getOrNull(texpr.getName());
        if (typeParameter != null) {
            if (texpr.getArgs().size() != 0) {
                throw CJError.of("type variables cannot accept arguments", texpr.getMark());
            }
            return new CJIRVariableType(typeParameter, List.of());
        }
        var typeItem = lctx.getTypeItem(texpr.getName(), texpr.getMark());
        var args = texpr.getArgs().map(te -> evalTypeExpression(te));
        checkArgc(texpr.getMark(), typeItem, args);
        return new CJIRClassType(typeItem, args);
    }

    private CJIRTypeParameter getVariable(String shortName, CJMark... marks) {
        var typeParameter = lctx.getItem().getTypeParameterMap().getOrNull(shortName);
        if (typeParameter == null) {
            throw CJError.of(shortName + " is not a variable", marks);
        }
        return typeParameter;
    }

    private void checkArgc(CJMark mark, CJIRItem item, List<CJIRType> args) {
        var expected = item.getTypeParameters().size();
        var actual = args.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " type args but got " + actual, mark, item.getMark());
        }
    }
}
