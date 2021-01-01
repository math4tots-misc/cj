package crossj.cj;

import crossj.base.List;

/**
 * Pass 2
 *
 * Create the type parameter's traits and item's trait declaration IRs
 *
 * TODO: verify trait constraints
 * (currently, only type argument count is checked)
 */
public final class CJPass02 extends CJPassBase {
    CJPass02(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        for (var typeParameter : item.getTypeParameters()) {
            var ast = typeParameter.getAst();
            for (var traitAst : ast.getTraits()) {
                var trait = evalTraitExpression(traitAst);
                typeParameter.getTraits().add(trait);
            }
        }
        for (var traitDeclarationAst : item.getAst().getTraitDeclarations()) {
            var trait = evalTraitExpression(traitDeclarationAst.getTrait());
            var traitDeclaration = new CJIRTraitDeclaration(traitDeclarationAst, trait);
            for (var conditionAst : traitDeclarationAst.getConditions()) {
                var variable = getVariable(conditionAst.getVariableName(), conditionAst.getMark());
                var condition = new CJIRTypeCondition(conditionAst, variable);
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
            return new CJIRVariableType(typeParameter);
        }
        var typeItem = lctx.getTypeItem(texpr.getName(), texpr.getMark());
        var args = texpr.getArgs().map(te -> evalTypeExpression(te));
        checkArgc(texpr.getMark(), typeItem, args);
        return new CJIRClassType(typeItem, args);
    }

    private CJIRVariableType getVariable(String shortName, CJMark... marks) {
        var typeParameter = lctx.getItem().getTypeParameterMap().getOrNull(shortName);
        if (typeParameter == null) {
            throw CJError.of(shortName + " is not a variable", marks);
        }
        return new CJIRVariableType(typeParameter);
    }

    private void checkArgc(CJMark mark, CJIRItem item, List<CJIRType> args) {
        var expected = item.getTypeParameters().size();
        var actual = args.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " type args but got " + actual, mark, item.getMark());
        }
    }
}
