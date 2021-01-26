package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;
import crossj.base.Pair;
import crossj.base.Range;
import crossj.base.Repr;
import crossj.base.Tuple3;
import crossj.base.Tuple4;

/**
 * Pass 4
 *
 * Resolve expressions
 */
final class CJPass04 extends CJPassBaseEx {
    private final List<Map<String, CJIRLocalVariableDeclaration>> locals = List.of();
    private final List<Pair<Boolean, CJIRType>> lambdaStack = List.of();

    CJPass04(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        for (var field : item.getFields()) {
            handleField(field);
        }
        for (var method : item.getMethods()) {
            handleMethod(method);
        }
    }

    private void enterScope() {
        locals.add(Map.of());
    }

    private void exitScope() {
        locals.pop();
    }

    private void enterLambdaScope(boolean isAsync) {
        enterScope();
        lambdaStack.add(Pair.of(isAsync, ctx.getNoReturnType()));
    }

    private void exitLambdaScope() {
        exitScope();
        lambdaStack.pop();
    }

    private boolean inAsyncContext() {
        if (lambdaStack.size() > 0) {
            return lambdaStack.last().get1();
        } else {
            return lctx.getMethod().map(m -> m.isAsync()).getOrElse(false);
        }
    }

    private CJIRType getCurrentExpectedReturnTypeOrNull() {
        if (lambdaStack.size() > 0) {
            return lambdaStack.last().get2();
        } else {
            return lctx.getMethod().map(m -> m.getInnerReturnType()).getOrElse(null);
        }
    }

    private CJIRLocalVariableDeclaration findLocalOrNull(String shortName) {
        for (int i = locals.size() - 1; i >= 0; i--) {
            var decl = locals.get(i).getOrNull(shortName);
            if (decl != null) {
                return decl;
            }
        }
        return null;
    }

    private CJIRLocalVariableDeclaration findLocal(String shortName, CJMark... marks) {
        var decl = findLocalOrNull(shortName);
        if (decl == null) {
            throw CJError.of("Variable " + Repr.of(shortName) + " not found", marks);
        }
        return decl;
    }

    private void declareLocal(CJIRLocalVariableDeclaration decl) {
        var name = decl.getName();
        var map = locals.last();
        if (map.containsKey(name)) {
            throw CJError.of("Variable " + name + " declared again", decl.getMark(), map.get(name).getMark());
        }
        map.put(name, decl);
    }

    private void handleField(CJIRField field) {
        if (field.getAst().getExpression().isEmpty()) {
            return;
        }
        var bodyAst = field.getAst().getExpression().get();
        enterScope();
        var body = evalExpressionWithType(bodyAst, field.getType());
        exitScope();
        field.setExpression(body);
    }

    private void handleMethod(CJIRMethod method) {
        if (method.getAst().getBody().isEmpty()) {
            return;
        }
        var bodyAst = method.getAst().getBody().get();
        enterMethod(method);
        enterScope();
        for (var parameter : method.getParameters()) {
            declareLocal(parameter);
        }
        var body = evalExpressionWithType(bodyAst, method.getInnerReturnType());
        exitScope();
        exitMethod();
        method.setBody(body);
    }

    private CJIRExpression evalExpression(CJAstExpression expression) {
        return evalExpressionEx(expression, Optional.empty());
    }

    private CJIRExpression evalBoolExpression(CJAstExpression expression) {
        var boolType = ctx.getBoolType();
        var ir = evalExpressionExUnchecked(expression, Optional.of(boolType));
        var actualType = ir.getType();
        if (actualType.equals(boolType)) {
            // Bool is required, and we got exactly a Bool
        } else if (actualType.implementsTrait(ctx.getToBoolTrait())) {
            // not a Bool, but convertible to Bool (ToBool)
            var methodRef = actualType.findMethod("toBool", expression.getMark());
            ir = synthesizeMethodCall(expression, actualType, methodRef, List.of(), List.of(ir));
        } else {
            throw CJError.of("Expected a Bool convertible value but got " + actualType, expression.getMark());
        }
        return ir;
    }

    private CJIRExpression evalUnitExpression(CJAstExpression expression) {
        return evalExpressionWithType(expression, ctx.getUnitType());
    }

    private CJIRMethodCall synthesizeMethodCall(CJAstExpression ast, CJIRType owner, CJIRMethodRef methodRef,
            List<CJIRType> typeArgs, List<CJIRExpression> args) {
        // this method cannot be reused in evalExpressionEx::visitMethodCall, because
        // the order
        // in which the method is resolved vs when the arguments are resolved are a bit
        // different.
        var reifiedMethodRef = ctx.checkMethodTypeArgs(owner, methodRef, typeArgs, ast.getMark());
        var parameterTypes = reifiedMethodRef.getParameterTypes();
        Assert.that(!methodRef.getMethod().isVariadic());
        checkArgc(parameterTypes, args, ast.getMark());
        for (int i = 0; i < args.size(); i++) {
            var parameterType = parameterTypes.get(i);
            var arg = args.get(i);
            checkResultType(arg.getMark(), parameterType, arg.getType());
        }
        var returnType = reifiedMethodRef.getReturnType();
        return new CJIRMethodCall(ast, returnType, owner, methodRef, typeArgs, args);
    }

    private CJIRMethodCall inferAndSynthesizeMethodCall(CJAstExpression ast, CJIRType owner, CJIRMethodRef methodRef,
            List<CJIRExpression> args, Optional<CJIRType> expectedReturnType) {
        var mark = ast.getMark();
        var typeArgs = inferMethodTypeArgs(mark, owner, methodRef, expectedReturnType, null, args);
        var reifiedMethodRef = ctx.checkMethodTypeArgs(owner, methodRef, typeArgs, ast.getMark());
        var parameterTypes = reifiedMethodRef.getParameterTypes();
        Assert.that(!methodRef.getMethod().isVariadic());
        checkArgc(parameterTypes, args, ast.getMark());
        for (int i = 0; i < args.size(); i++) {
            var parameterType = parameterTypes.get(i);
            var arg = args.get(i);
            checkResultType(arg.getMark(), parameterType, arg.getType());
        }
        var returnType = reifiedMethodRef.getReturnType();
        return new CJIRMethodCall(ast, returnType, owner, methodRef, typeArgs, args);
    }

    private CJIRExpression evalExpressionWithType(CJAstExpression expression, CJIRType type) {
        return evalExpressionEx(expression, Optional.of(type));
    }

    private CJIRExpression evalExpressionEx(CJAstExpression expression, Optional<CJIRType> a) {
        var ir = evalExpressionExUnchecked(expression, a);
        if (a.isPresent()) {
            var expectedType = a.get();
            var actualType = ir.getType();
            if (!actualType.equals(expectedType) && !actualType.equals(ctx.getNoReturnType())
                    && !expectedType.equals(ctx.getUnitType())) {
                var methodName = expectedType.getImplicitMethodNameForTypeOrNull(actualType);
                if (methodName != null) {
                    var methodRef = expectedType.findMethod(methodName, expression.getMark());
                    ir = inferAndSynthesizeMethodCall(expression, expectedType, methodRef, List.of(ir), a);
                    actualType = ir.getType();
                }
            }
            checkResultType(expression.getMark(), expectedType, actualType);
        }
        return ir;
    }

    private void checkResultType(CJMark mark, CJIRType expectedType, CJIRType actualType) {
        if (expectedType.equals(ctx.getUnitType()) || actualType.equals(ctx.getNoReturnType())) {
            // when the expected type is Unit or the expression's type is NoReturn,
            // by default we forgo the check.
        } else if (!expectedType.equals(actualType)) {
            throw CJError.of("Expected " + expectedType + " but got " + actualType, mark);
        }
    }

    private CJIRExpression evalExpressionExUnchecked(CJAstExpression expression, Optional<CJIRType> a) {
        var ir = expression.accept(new CJAstExpressionVisitor<CJIRExpression, Optional<CJIRType>>() {

            @Override
            public CJIRExpression visitLiteral(CJAstLiteral e, Optional<CJIRType> a) {
                switch (e.getKind()) {
                    case Unit:
                        return new CJIRLiteral(e, ctx.getUnitType(), e.getKind(), e.getRawText());
                    case Bool:
                        return new CJIRLiteral(e, ctx.getBoolType(), e.getKind(), e.getRawText());
                    case Char:
                        return new CJIRLiteral(e, ctx.getCharType(), e.getKind(), e.getRawText());
                    case Int:
                        return new CJIRLiteral(e, ctx.getIntType(), e.getKind(), e.getRawText());
                    case Double:
                        return new CJIRLiteral(e, ctx.getDoubleType(), e.getKind(), e.getRawText());
                    case String:
                        return new CJIRLiteral(e, ctx.getStringType(), e.getKind(), e.getRawText());
                }
                throw CJError.of("TODO evalExpression-visitBlock", e.getMark());
            }

            @Override
            public CJIRExpression visitBlock(CJAstBlock e, Optional<CJIRType> a) {
                enterScope();
                var noReturnType = ctx.getNoReturnType();
                var exprs = e.getExpressions();
                if (exprs.size() == 0) {
                    return new CJIRLiteral(e, ctx.getUnitType(), CJIRLiteralKind.Unit, "");
                }
                var newExprs = List.<CJIRExpression>of();
                for (int i = 0; i + 1 < exprs.size(); i++) {
                    var newExpr = evalUnitExpression(exprs.get(i));
                    newExprs.add(newExpr);
                    if (newExpr.getType().equals(noReturnType)) {
                        throw CJError.of("Unreachable code", exprs.get(i + 1).getMark());
                    }
                }
                newExprs.add(evalExpressionEx(exprs.last(), a));
                exitScope();

                if (newExprs.size() == 1 && !(newExprs.get(0) instanceof CJIRVariableDeclaration)) {
                    return newExprs.get(0);
                }

                return new CJIRBlock(e, newExprs.last().getType(), newExprs);
            }

            @Override
            public CJIRExpression visitMethodCall(CJAstMethodCall e, Optional<CJIRType> a) {
                List<CJIRType> typeArgs;
                var args = List.<CJIRExpression>of();
                CJIRType owner;
                var argAsts = e.getArgs();

                if (e.getOwner().isEmpty()) {
                    // For a "non-static" method call, the first argument must always be
                    // evaluated without bound to determine the owner type.
                    args = List.of(evalExpression(argAsts.get(0)));
                    owner = args.get(0).getType();
                } else {
                    // For "static" method calls, no expressions have to be evaluated
                    // to determine the owner type.
                    args = List.of();
                    owner = lctx.evalTypeExpression(e.getOwner().get());
                }
                var methodRef = owner.findMethod(e.getName(), e.getMark());

                // The returned method call might be used with an implicit method call
                // to account for that, we preemptively check here whether the conditions
                // are ripe for a conversion method call. An d if so, we see if it's possible
                // to use that method's argument type as the expected type instead.
                if (a.isPresent()) {
                    var mrtype = methodRef.getMethod().getReturnType();
                    var etype = a.get();
                    // If the method return type is NoReturn, there's no use trying to infer with
                    // it.
                    if (!mrtype.isNoReturnType()) {
                        // Here we check to see if etype has an implicit declaration that will
                        // allow mrtype to convert to etype.
                        // If such a declaration is found, we check if the method's argument
                        // is absolute. If so, we can use that method's argument type as
                        // the etype rather than the given etype.
                        if (mrtype instanceof CJIRClassType) {
                            var newExpectedType = getNewExpectedTypeBasedOnImplicits(e.getMark(), etype,
                                    ((CJIRClassType) mrtype).getItem());
                            if (newExpectedType.isPresent()) {
                                a = newExpectedType;
                            }
                        }
                    }
                }

                if (methodRef.getMethod().isVariadic()) {
                    // if this is a variadic method, wrap trailing args in a list display
                    var split = methodRef.getMethod().getParameters().size() - 1;
                    var newArgAsts = argAsts.sliceUpto(split);
                    newArgAsts.add(new CJAstListDisplay(e.getMark(), argAsts.sliceFrom(split)));

                    // If we had to evaluate the first argument to determine the owner type,
                    // make sure that we didn't change it.
                    // Theoretically we could support this case, but it would require a bit more
                    // case handling.
                    if (e.getOwner().isEmpty() && argAsts.get(0) != newArgAsts.get(0)) {
                        throw CJError.of("The owner argument cannot be part of a variadic list", e.getMark());
                    }
                    argAsts = newArgAsts;
                }

                if (e.getTypeArgs().size() == 0 && methodRef.getMethod().getTypeParameters().size() > 0) {
                    // If no type arguments are provided, and the method has type parameters,
                    // try to infer them.
                    typeArgs = inferMethodTypeArgs(e.getMark(), owner, methodRef, a, argAsts, args);
                } else {
                    // use the given type arguments as is
                    typeArgs = e.getTypeArgs().map(lctx::evalTypeExpression);
                }
                var reifiedMethodRef = ctx.checkMethodTypeArgs(owner, methodRef, typeArgs, e.getMark());
                var parameterTypes = reifiedMethodRef.getParameterTypes();
                checkArgc(parameterTypes, argAsts, e.getMark());
                while (args.size() < parameterTypes.size()) {
                    var parameterType = parameterTypes.get(args.size());
                    var argAst = argAsts.get(args.size());
                    args.add(evalExpressionWithType(argAst, parameterType));
                }
                var returnType = reifiedMethodRef.getReturnType();
                return new CJIRMethodCall(e, returnType, owner, methodRef, typeArgs, args);
            }

            @Override
            public CJIRExpression visitVariableDeclaration(CJAstVariableDeclaration e, Optional<CJIRType> a) {
                CJIRType expressionType;
                CJIRExpression expression;
                if (e.getDeclaredType().isPresent()) {
                    expressionType = lctx.evalTypeExpression(e.getDeclaredType().get());
                    expression = evalExpressionWithType(e.getExpression(), expressionType);
                } else {
                    expression = evalExpression(e.getExpression());
                    expressionType = expression.getType();
                }
                var target = evalDeclarableTarget(e.getTarget(), e.isMutable(), expressionType);
                var decl = new CJIRVariableDeclaration(e, ctx.getUnitType(), e.isMutable(), target, expression);
                declareTarget(target);
                return decl;
            }

            @Override
            public CJIRExpression visitVariableAccess(CJAstVariableAccess e, Optional<CJIRType> a) {
                var target = findLocalOrNull(e.getName());
                if (target != null) {
                    return new CJIRVariableAccess(e, target);
                }
                if (!e.getName().equals("self")) {
                    // Check for Self.* and self.* variables
                    var selfType = lctx.getSelfType();
                    var methodRef = selfType.findMethodOrNull("__get_" + e.getName());
                    if (methodRef != null) {
                        var method = methodRef.getMethod();
                        if (method.getParameters().size() == 0) {
                            return synthesizeMethodCall(e, selfType, methodRef, List.of(), List.of());
                        } else if (method.getParameters().size() == 1) {
                            var selfDecl = findLocalOrNull("self");
                            if (selfDecl == null) {
                                throw CJError.of(
                                        "Non-static field " + e.getName() + " cannot be used without a 'self' in scope",
                                        e.getMark());
                            }
                            return synthesizeMethodCall(e, selfType, methodRef, List.of(),
                                    List.of(new CJIRVariableAccess(e, selfDecl)));
                        }
                    }
                }
                return new CJIRVariableAccess(e, findLocal(e.getName(), e.getMark()));
            }

            @Override
            public CJIRExpression visitAssignment(CJAstAssignment e, Optional<CJIRType> a) {
                if (e.getTarget() instanceof CJAstNameAssignmentTarget) {
                    // Check for Self.* and self.* variables
                    var nameMark = e.getTarget().getMark();
                    var name = ((CJAstNameAssignmentTarget) e.getTarget()).getName();
                    var decl = findLocalOrNull(name);
                    if (decl == null) {
                        var selfType = lctx.getSelfType();
                        var methodRef = selfType.findMethodOrNull("__set_" + name);
                        if (methodRef != null) {
                            var method = methodRef.getMethod();
                            if (method.getParameters().size() == 1) {
                                return evalUnitExpression(new CJAstMethodCall(e.getMark(),
                                        Optional.of(new CJAstTypeExpression(e.getMark(), "Self", List.of())),
                                        "__set_" + name, List.of(), List.of(e.getExpression())));
                            } else if (method.getParameters().size() == 2) {
                                var selfDecl = findLocalOrNull("self");
                                if (selfDecl == null) {
                                    throw CJError.of("Non-static field " + name
                                            + " cannot be assigned without a 'self' in scope", nameMark);
                                }
                                return evalUnitExpression(new CJAstMethodCall(e.getMark(),
                                        Optional.of(new CJAstTypeExpression(e.getMark(), "Self", List.of())),
                                        "__set_" + name, List.of(),
                                        List.of(new CJAstVariableAccess(e.getMark(), "self"), e.getExpression())));
                            }
                        }
                    }
                }
                var target = evalAssignableTarget(e.getTarget());
                var expr = evalExpressionWithType(e.getExpression(), target.getTargetType());
                return new CJIRAssignment(e, target.getTargetType(), target, expr);
            }

            @Override
            public CJIRExpression visitAugmentedAssignment(CJAstAugmentedAssignment e, Optional<CJIRType> a) {
                var target = findLocal(e.getTarget(), e.getMark());
                var targetType = target.getVariableType();
                if (targetType.equals(ctx.getIntType()) || targetType.equals(ctx.getDoubleType())) {
                    var expression = evalExpressionWithType(e.getExpression(), target.getVariableType());
                    return new CJIRAugmentedAssignment(e, ctx.getUnitType(), target, e.getKind(), expression);
                } else {
                    throw CJError.of("Augmented assignments are only supported for int and double values", e.getMark());
                }
            }

            @Override
            public CJIRExpression visitLogicalNot(CJAstLogicalNot e, Optional<CJIRType> a) {
                var inner = evalBoolExpression(e.getInner());
                return new CJIRLogicalNot(e, ctx.getBoolType(), inner);
            }

            @Override
            public CJIRExpression visitLogicalBinop(CJAstLogicalBinop e, Optional<CJIRType> a) {
                var left = evalBoolExpression(e.getLeft());
                var right = evalBoolExpression(e.getRight());
                return new CJIRLogicalBinop(e, ctx.getBoolType(), e.isAnd(), left, right);
            }

            @Override
            public CJIRExpression visitIs(CJAstIs e, Optional<CJIRType> a) {
                var left = evalExpression(e.getLeft());
                var right = evalExpressionWithType(e.getRight(), left.getType());
                return new CJIRIs(e, ctx.getBoolType(), left, right);
            }

            @Override
            public CJIRExpression visitNullWrap(CJAstNullWrap e, Optional<CJIRType> a) {
                CJIRType innerType;
                Optional<CJIRExpression> inner;
                if (e.getInnerType().isPresent() || a.isPresent()) {
                    innerType = e.getInnerType().map(lctx::evalTypeExpression).getOrElseDo(() -> {
                        var expectedType = a.get();
                        if (!expectedType.isNullableType()) {
                            throw CJError.of("Expected " + expectedType + " but got a nullable expression",
                                    e.getMark());
                        }
                        return ((CJIRClassType) expectedType).getArgs().get(0);
                    });
                    inner = e.getInner().map(i -> evalExpressionWithType(i, innerType));
                } else if (e.getInner().isPresent()) {
                    var inner0 = evalExpression(e.getInner().get());
                    inner = Optional.of(inner0);
                    innerType = inner0.getType();
                } else {
                    throw CJError.of("Could not infer type of null expression", e.getMark());
                }
                return new CJIRNullWrap(e, ctx.getNullableType(innerType, e.getMark()), inner);
            }

            @Override
            public CJIRExpression visitListDisplay(CJAstListDisplay e, Optional<CJIRType> a) {
                if (a.isEmpty() && e.getExpressions().isEmpty()) {
                    throw CJError.of("Could not determine type of list display", e.getMark());
                }
                if (a.isPresent()) {
                    var newExpectedType = getNewExpectedTypeBasedOnImplicits(e.getMark(), a.get(), ctx.getListItem());
                    if (newExpectedType.isPresent()) {
                        a = newExpectedType;
                    }
                }

                var itemType = a.map(expectedType -> {
                    // TODO: Consider whether to be permissive in the case where expectedType is a
                    // Bool
                    if (!expectedType.isListType()) {
                        throw CJError.of("Expected " + expectedType + " but got a list display", e.getMark());
                    }
                    var listType = (CJIRClassType) expectedType;
                    return listType.getArgs().get(0);
                });
                var expressions = List.<CJIRExpression>of();
                for (var expressionAst : e.getExpressions()) {
                    var expression = evalExpressionEx(expressionAst, itemType);
                    expressions.add(expression);
                    if (itemType.isEmpty()) {
                        itemType = Optional.of(expression.getType());
                    }
                }
                return new CJIRListDisplay(e, ctx.getListType(itemType.get()), expressions);
            }

            @Override
            public CJIRExpression visitTupleDisplay(CJAstTupleDisplay e, Optional<CJIRType> a) {
                if (a.isEmpty()) {
                    var expressions = e.getExpressions().map(x -> evalExpression(x));
                    var argTypes = expressions.map(x -> x.getType());
                    var tupleTypeName = "cj.Tuple" + expressions.size();
                    var tupleType = ctx.getTypeWithArgs(tupleTypeName, argTypes, e.getMark());
                    return new CJIRTupleDisplay(e, tupleType, expressions);
                } else {
                    var expectedType = a.get();
                    if (!expectedType.isTupleType()) {
                        throw CJError.of("Expected " + expectedType + " but got a tuple display", e.getMark());
                    }
                    var displayItemName = "cj.Tuple" + e.getExpressions().size();
                    var classType = (CJIRClassType) expectedType;
                    if (!classType.getItem().getFullName().equals(displayItemName)) {
                        throw CJError.of("Expected " + classType + " but got a " + displayItemName, e.getMark());
                    }
                    var expressions = List.<CJIRExpression>of();
                    var argAsts = e.getExpressions();
                    var expectedTypes = classType.getArgs();
                    for (int i = 0; i < expectedTypes.size(); i++) {
                        expressions.add(evalExpressionWithType(argAsts.get(i), expectedTypes.get(i)));
                    }
                    return new CJIRTupleDisplay(e, expectedType, expressions);
                }
            }

            @Override
            public CJIRExpression visitIf(CJAstIf e, Optional<CJIRType> a) {
                var condition = evalBoolExpression(e.getCondition());
                CJIRType returnType;
                CJIRExpression left;
                if (e.getRight().isEmpty()) {
                    returnType = ctx.getUnitType();
                    left = evalExpressionWithType(e.getLeft(), returnType);
                } else if (a.isPresent()) {
                    returnType = a.get();
                    left = evalExpressionWithType(e.getLeft(), returnType);
                } else {
                    left = evalExpression(e.getLeft());
                    returnType = left.getType();
                    // TODO: Do the "correct" thing here
                    // HACK: If the first branch is a NoReturn, relax the return type to a unit
                    if (returnType.isNoReturnType()) {
                        returnType = ctx.getUnitType();
                    }
                }
                var rightAst = e.getRight().getOrElseDo(() -> new CJAstLiteral(e.getMark(), CJIRLiteralKind.Unit, ""));
                var right = evalExpressionWithType(rightAst, returnType);
                return new CJIRIf(e, returnType, condition, left, right);
            }

            @Override
            public CJIRExpression visitIfNull(CJAstIfNull e, Optional<CJIRType> a) {
                var inner = evalExpression(e.getExpression());
                if (!inner.getType().isNullableType()) {
                    throw CJError.of("Expected nullable type", inner.getMark());
                }
                var targetType = ((CJIRClassType) inner.getType()).getArgs().get(0);
                var target = evalDeclarableTarget(e.getTarget(), e.isMutable(), targetType);
                CJIRType returnType;
                CJIRExpression left;
                if (e.getRight().isEmpty()) {
                    returnType = ctx.getUnitType();
                    enterScope();
                    declareTarget(target);
                    left = evalExpressionWithType(e.getLeft(), returnType);
                    exitScope();
                } else if (a.isPresent()) {
                    returnType = a.get();
                    enterScope();
                    declareTarget(target);
                    left = evalExpressionWithType(e.getLeft(), returnType);
                    exitScope();
                } else {
                    enterScope();
                    declareTarget(target);
                    left = evalExpression(e.getLeft());
                    exitScope();
                    returnType = left.getType();
                    // TODO: Do the "correct" thing here
                    // HACK: If the first branch is a NoReturn, relax the return type to a unit
                    if (returnType.isNoReturnType()) {
                        returnType = ctx.getUnitType();
                    }
                }
                var rightAst = e.getRight().getOrElseDo(() -> new CJAstLiteral(e.getMark(), CJIRLiteralKind.Unit, ""));
                var right = evalExpressionWithType(rightAst, returnType);
                return new CJIRIfNull(e, returnType, e.isMutable(), target, inner, left, right);
            }

            @Override
            public CJIRExpression visitWhile(CJAstWhile e, Optional<CJIRType> a) {
                var unitType = ctx.getUnitType();
                var condition = evalBoolExpression(e.getCondition());
                var body = evalUnitExpression(e.getBody());
                return new CJIRWhile(e, unitType, condition, body);
            }

            @Override
            public CJIRExpression visitFor(CJAstFor e, Optional<CJIRType> a) {
                var container = evalExpression(e.getContainer());
                var iterable = container.getType().getImplementingTraitByItemOrNull(ctx.getIterableItem());
                if (iterable == null) {
                    throw CJError.of("For loop requires an iterable, but got " + container.getType(), e.getMark());
                }
                var methodRef = container.getType().findMethod("iter", e.getMark());
                var iterator = synthesizeMethodCall(e, container.getType(), methodRef, List.of(), List.of(container));
                var targetType = iterable.getArgs().get(0);
                enterScope();
                var target = evalDeclarableTarget(e.getTarget(), false, targetType);
                declareTarget(target);
                var ifCondition = e.getIfCondition().map(b -> evalBoolExpression(b));
                var whileCondition = e.getWhileCondition().map(b -> evalBoolExpression(b));
                var body = evalUnitExpression(e.getBody());
                exitScope();
                return new CJIRFor(e, ctx.getUnitType(), target, iterator, ifCondition, whileCondition, body);
            }

            @Override
            public CJIRExpression visitUnion(CJAstUnion e, Optional<CJIRType> a) {
                var target = evalExpression(e.getTarget());
                if (!target.getType().isUnionType()) {
                    throw CJError.of(target.getType() + " is not a union type", target.getMark());
                }
                var type = (CJIRClassType) target.getType();
                var bindings = type.getBindingWithSelfType(type);
                var casesByTag = type.getItem().getCases();
                var caseNamesByTag = casesByTag.map(defn -> defn.getName());
                var caseTypesByTag = casesByTag.map(defn -> defn.getTypes().map(bindings::apply));
                var caseTagsByName = Map
                        .fromIterable(Range.upto(casesByTag.size()).map(i -> Pair.of(caseNamesByTag.get(i), i)));
                var sieve = Range.upto(caseTypesByTag.size()).map(i -> false).list();
                var cases = List.<Tuple4<CJMark, CJIRCase, List<CJIRAdHocVariableDeclaration>, CJIRExpression>>of();
                for (var caseAst : e.getCases()) {
                    var caseMark = caseAst.get1();
                    var caseName = caseAst.get2();
                    var caseVars = caseAst.get3();
                    var caseBody = caseAst.get4();
                    var tag = caseTagsByName.getOrNull(caseName);
                    if (sieve.get(tag)) {
                        throw CJError.of("Duplicate entry for " + caseName, caseMark);
                    }
                    sieve.set(tag, true);
                    if (tag == null) {
                        throw CJError.of(caseName + " is not a case in " + type, caseMark);
                    }
                    var caseDefn = casesByTag.get(tag);
                    if (caseDefn.getTypes().size() != caseVars.size()) {
                        throw CJError.of(caseName + " expects " + caseDefn.getTypes().size() + " args but got "
                                + caseVars.size(), caseMark);
                    }
                    var caseTypes = caseDefn.getTypes().map(bindings::apply);
                    var vars = Range.upto(caseTypes.size()).map(i -> {
                        var varAst = caseVars.get(i);
                        var varMark = varAst.get1();
                        var mutable = varAst.get2();
                        var varName = varAst.get3();
                        var varType = caseTypes.get(i);
                        return new CJIRAdHocVariableDeclaration(varMark, mutable, varName, varType);
                    }).list();
                    enterScope();
                    vars.forEach(t -> declareLocal(t));
                    var body = evalExpressionEx(caseBody, a);
                    exitScope();
                    if (a.isEmpty()) {
                        a = Optional.of(body.getType());
                    }
                    cases.add(Tuple4.of(caseMark, caseDefn, vars, body));
                }
                Optional<CJIRExpression> fallback;
                if (e.getFallback().isPresent()) {
                    fallback = Optional.of(evalExpressionEx(e.getFallback().get(), a));
                    if (a.isEmpty()) {
                        a = Optional.of(fallback.get().getType());
                    }
                } else {
                    fallback = Optional.empty();
                    var missingCases = List.<String>of();
                    for (int i = 0; i < sieve.size(); i++) {
                        if (!sieve.get(i)) {
                            missingCases.add(caseNamesByTag.get(i));
                        }
                    }
                    if (missingCases.size() > 0) {
                        var itemName = type.getItem().getFullName();
                        throw CJError.of("Missing union cases for " + itemName + ": " + missingCases, e.getMark());
                    }
                    if (sieve.isEmpty()) {
                        throw CJError.of("Empty unions require at least a default case", e.getMark());
                    }
                }
                return new CJIRUnion(e, a.get(), target, cases, fallback);
            }

            @Override
            public CJIRExpression visitSwitch(CJAstSwitch e, Optional<CJIRType> a) {
                var target = evalExpression(e.getTarget());
                var targetType = target.getType();
                var switchPermittedTypes = List.of(ctx.getIntType(), ctx.getCharType(), ctx.getStringType());
                // TODO: Reconsider this
                if (!switchPermittedTypes.contains(targetType)) {
                    throw CJError.of(targetType + " may not be used in a switch", e.getMark());
                }
                var cases = List.<Pair<List<CJIRExpression>, CJIRExpression>>of();
                for (var case_ : e.getCases()) {
                    var expressions = case_.get1().map(c -> evalExpressionWithType(c, targetType));
                    var body = evalExpressionEx(case_.get2(), a);
                    if (a.isEmpty()) {
                        a = Optional.of(body.getType());
                    }
                    cases.add(Pair.of(expressions, body));
                }
                Optional<CJIRExpression> fallback = Optional.empty();
                if (e.getFallback().isPresent()) {
                    var fallbackAst = e.getFallback().get();
                    var body = evalExpressionEx(fallbackAst, a);
                    if (a.isEmpty()) {
                        a = Optional.of(body.getType());
                    }
                    fallback = Optional.of(body);
                }
                if (a.isEmpty()) {
                    throw CJError.of("switch must have at least one case or a default", e.getMark());
                }
                return new CJIRSwitch(e, a.get(), target, cases, fallback);
            }

            @Override
            public CJIRExpression visitLambda(CJAstLambda e, Optional<CJIRType> a) {
                if (a.isEmpty()) {
                    throw CJError.of("Could not infer type of lambda expression", e.getMark());
                }
                var type = a.get();
                if (!type.isFunctionType()) {
                    throw CJError.of("Expected " + type + " but got a lambda expression", e.getMark());
                }
                var fnType = (CJIRClassType) type;
                var fnTypeArgs = fnType.getArgs();
                var returnType = fnTypeArgs.get(fnTypeArgs.size() - 1);
                var parameterTypes = fnTypeArgs.slice(0, fnTypeArgs.size() - 1);
                var parameterAsts = e.getParameters();
                if (parameterTypes.size() != parameterAsts.size()) {
                    throw CJError.of("Expected " + parameterTypes.size()
                            + " arg function but got a lambda expression with " + parameterAsts.size() + " parameters",
                            e.getMark());
                }
                var parameters = Range.upto(parameterAsts.size()).map(i -> {
                    var parameterType = parameterTypes.get(i);
                    var parameterAst = parameterAsts.get(i);
                    var paramMark = parameterAst.get1();
                    var mutable = parameterAst.get2();
                    var name = parameterAst.get3();
                    return new CJIRAdHocVariableDeclaration(paramMark, mutable, name, parameterType);
                }).list();
                enterLambdaScope(e.isAsync());
                parameters.forEach(p -> declareLocal(p));
                var body = evalExpressionWithType(e.getBody(), returnType);
                exitLambdaScope();
                return new CJIRLambda(e, type, e.isAsync(), parameters, body);
            }

            @Override
            public CJIRExpression visitReturn(CJAstReturn e, Optional<CJIRType> a) {
                var unitType = ctx.getUnitType();
                var expectedReturnType = getCurrentExpectedReturnTypeOrNull();
                if (expectedReturnType == null) {
                    throw CJError.of("Tried to return outside of a function or method", e.getMark());
                }
                var inner = evalExpressionWithType(e.getExpression(), expectedReturnType);
                if (!inner.getType().equals(unitType) && expectedReturnType.equals(unitType)) {
                    // by normal type checking rules, returning non-unit from function that returns
                    // unit is actually fine, however, in explicit returns this seems like a bug.
                    throw CJError.of("Function returns unit type, but a non-unit was returned", e.getMark());
                }
                return new CJIRReturn(e, ctx.getNoReturnType(), inner);
            }

            @Override
            public CJIRExpression visitAwait(CJAstAwait e, Optional<CJIRType> a) {
                if (!inAsyncContext()) {
                    throw CJError.of("Await can only be used from inside an async method", e.getMark());
                }
                var optionalExpectedInnerType = a.map(ctx::getPromiseType);
                var inner = evalExpressionEx(e.getInner(), optionalExpectedInnerType);
                var innerType = inner.getType();
                if (!innerType.isPromiseType()) {
                    throw CJError.of("Await expects a Promise expression but got " + innerType, e.getMark());
                }
                var outerType = ((CJIRClassType) innerType).getArgs().get(0);
                return new CJIRAwait(e, outerType, inner);
            }

            @Override
            public CJIRExpression visitThrow(CJAstThrow e, Optional<CJIRType> a) {
                var expression = evalExpression(e.getExpression());
                return new CJIRThrow(e, ctx.getNoReturnType(), expression);
            }

            @Override
            public CJIRExpression visitTry(CJAstTry e, Optional<CJIRType> a) {
                var body = evalExpressionEx(e.getBody(), a);
                if (a.isEmpty()) {
                    a = Optional.of(body.getType());
                }
                var fa = a;
                var clauses = e.getClauses().map(clause -> {
                    var excType = lctx.evalTypeExpression(clause.get2());
                    var target = evalDeclarableTarget(clause.get1(), false, excType);
                    enterScope();
                    declareTarget(target);
                    var clauseBody = evalExpressionEx(clause.get3(), fa);
                    exitScope();
                    return Tuple3.of(target, excType, clauseBody);
                });
                var fin = e.getFin().map(f -> evalExpressionEx(f, fa));
                return new CJIRTry(e, a.get(), body, clauses, fin);
            }
        }, a);
        return ir;
    }

    private CJIRAssignmentTarget evalDeclarableTarget(CJAstAssignmentTarget target, boolean mutable, CJIRType type) {
        return target.accept(new CJAstAssignmentTargetVisitor<CJIRAssignmentTarget, Void>() {
            @Override
            public CJIRAssignmentTarget visitName(CJAstNameAssignmentTarget t, Void a) {
                return new CJIRNameAssignmentTarget(t, mutable, t.getName(), type);
            }

            @Override
            public CJIRAssignmentTarget visitTuple(CJAstTupleAssignmentTarget t, Void a) {
                if (!type.isTupleType()) {
                    throw CJError.of("Expected " + type + " but got tuple assignment target", target.getMark());
                }
                var typeArgs = ((CJIRClassType) type).getArgs();
                var subtargetAsts = t.getSubtargets();
                if (typeArgs.size() != subtargetAsts.size()) {
                    throw CJError.of(
                            "Expected Tuple" + typeArgs.size() + " but found Tuple" + subtargetAsts.size() + " target",
                            t.getMark());
                }
                var subtargets = List.<CJIRAssignmentTarget>of();
                for (int i = 0; i < typeArgs.size(); i++) {
                    subtargets.add(evalDeclarableTarget(subtargetAsts.get(i), mutable, typeArgs.get(i)));
                }
                return new CJIRTupleAssignmentTarget(target, subtargets, type);
            }
        }, null);
    }

    private void declareTarget(CJIRAssignmentTarget target) {
        target.accept(new CJIRAssignmentTargetVisitor<Void, Void>() {
            @Override
            public Void visitName(CJIRNameAssignmentTarget t, Void a) {
                declareLocal(t);
                return null;
            }

            @Override
            public Void visitTuple(CJIRTupleAssignmentTarget t, Void a) {
                t.getSubtargets().forEach(s -> declareTarget(s));
                return null;
            }
        }, null);
    }

    private CJIRAssignmentTarget evalAssignableTarget(CJAstAssignmentTarget target) {
        return target.accept(new CJAstAssignmentTargetVisitor<CJIRAssignmentTarget, Void>() {
            @Override
            public CJIRAssignmentTarget visitName(CJAstNameAssignmentTarget t, Void a) {
                var name = t.getName();
                var decl = findLocal(name, t.getMark());
                if (!decl.isMutable()) {
                    throw CJError.of(name + " is not mutable", decl.getMark());
                }
                return new CJIRNameAssignmentTarget(t, true, name, decl.getVariableType());
            }

            @Override
            public CJIRAssignmentTarget visitTuple(CJAstTupleAssignmentTarget t, Void a) {
                var subtargets = t.getSubtargets().map(s -> evalAssignableTarget(s));
                var type = ctx.getTupleType(subtargets.map(s -> s.getTargetType()), t.getMark());
                return new CJIRTupleAssignmentTarget(t, subtargets, type);
            }
        }, null);
    }

    private void checkArgc(List<CJIRType> parameterTypes, List<?> exprs, CJMark mark) {
        var expected = parameterTypes.size();
        var actual = exprs.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " args but got " + actual, mark);
        }
    }

    private Optional<CJIRType> getNewExpectedTypeBasedOnImplicits(CJMark mark, CJIRType expectedType,
            CJIRItem actualItem) {
        if (!(expectedType instanceof CJIRClassType)) {
            return Optional.empty();
        }
        var etypeItem = ((CJIRClassType) expectedType).getItem();
        if (etypeItem == actualItem) {
            return Optional.empty();
        }
        var methodName = etypeItem.getImplicitsTypeItemMap().getOrNull(actualItem);
        if (methodName == null) {
            return Optional.empty();
        }
        var implicitMethodRef = expectedType.findMethod(methodName, mark);
        var params = implicitMethodRef.getMethod().getParameters();
        if (params.size() != 1) {
            throw CJError.of("Invalid implicit method " + actualItem.getFullName() + " -> " + expectedType + " ("
                    + methodName + ")", implicitMethodRef.getMark());
        }
        var candidate = params.get(0).getVariableType();
        return candidate.isAbsoluteType() ? Optional.of(candidate) : Optional.empty();
    }

    private List<CJIRType> inferMethodTypeArgs(CJMark mark, CJIRType selfType, CJIRMethodRef methodRef,
            Optional<CJIRType> expectedReturnType, List<CJAstExpression> args,
            List<CJIRExpression> alreadyEvaluatedExpressions) {
        var itemBinding = methodRef.getOwner().getBindingWithSelfType(selfType);
        var stack = List.<Tuple3<CJMark, CJIRType, CJIRType>>of();
        var exprs = alreadyEvaluatedExpressions;
        var map = Map.<String, CJIRType>of();
        var typeParameters = methodRef.getMethod().getTypeParameters();
        var target = typeParameters.size();
        var parameters = methodRef.getMethod().getParameters();
        var exprsLimit = Math.min(args == null ? parameters.size() : args.size(), parameters.size());
        int nextInferArgIndex = 0;

        if (expectedReturnType.isPresent()) {
            var mrtype = methodRef.getMethod().getReturnType();
            var etype = expectedReturnType.get();
            // If the method return type is NoReturn, there's no use trying to infer with
            // it.
            if (!mrtype.isNoReturnType()) {
                stack.add(Tuple3.of(mark, mrtype, etype));
            }
        }

        while (map.size() < target && (stack.size() > 0 || nextInferArgIndex < exprsLimit)) {
            if (stack.size() == 0) {
                // if the stack is empty but we have more arguments we can look at, use it.
                int i = nextInferArgIndex++;
                var parameterType = parameters.get(i).getVariableType();
                var parameterMark = parameters.get(i).getMark();
                var inferMark = mark;
                CJIRExpression expr;
                if (i < exprs.size()) {
                    // if the expression has already been resolved, just use it
                    expr = exprs.get(i);
                } else {
                    // if the expression has not already been resolved, we need to resolve it
                    // with the limited context we have here.
                    var arg = args.get(i);
                    inferMark = arg.getMark();
                    if (arg instanceof CJAstLambda) {
                        var lambdaAst = (CJAstLambda) arg;
                        expr = handleLambdaTypeForMethodInference(mark, parameterType, parameterMark, lambdaAst,
                                itemBinding, map);
                    } else {
                        expr = evalExpression(arg);
                    }
                    exprs.add(expr);
                }
                stack.add(Tuple3.of(inferMark, parameterType, expr.getType()));
            }
            var triple = stack.pop();
            var inferMark = triple.get1();
            var param = triple.get2();
            var given = triple.get3();

            // TODO: More thorough checking
            if (param instanceof CJIRVariableType) {
                var variableType = (CJIRVariableType) param;
                var variableName = variableType.getName();
                if (!itemBinding.containsKey(variableName) && !map.containsKey(variableName)) {
                    Assert.that(variableType.isMethodLevel());

                    // this is a free variable. Let's bind it.
                    map.put(variableName, given);

                    // we also use the trait bounds of this variable to add more inferences
                    for (var bound : variableType.getDeclaration().getTraits()) {
                        var givenImplTrait = given.getImplementingTraitByItemOrNull(bound.getItem());
                        if (givenImplTrait == null) {
                            throw CJError.of(given + " does not implement required bound " + bound, inferMark,
                                    variableType.getDeclaration().getMark());
                        }
                        for (int i = 0; i < bound.getArgs().size(); i++) {
                            var typeFromBound = bound.getArgs().get(i);
                            var typeFromGiven = givenImplTrait.getArgs().get(i);
                            stack.add(Tuple3.of(variableType.getDeclaration().getMark(), typeFromBound, typeFromGiven));
                        }
                    }
                }
            } else if (param instanceof CJIRClassType) {
                var classTypeParam = (CJIRClassType) param;
                if (!(given instanceof CJIRClassType)) {
                    throw CJError.of("Expected argument of form " + param + " but got " + given, inferMark);
                }
                var classTypeGiven = (CJIRClassType) given;
                if (classTypeParam.getItem() != classTypeGiven.getItem()
                        || classTypeParam.getArgs().size() != classTypeGiven.getArgs().size()) {
                    throw CJError.of("Expected argument of form " + param + " but got " + given, inferMark);
                }
                for (int i = 0; i < classTypeGiven.getArgs().size(); i++) {
                    stack.add(Tuple3.of(inferMark, classTypeParam.getArgs().get(i), classTypeGiven.getArgs().get(i)));
                }
            }
        }

        if (map.size() < target) {
            throw CJError.of("Could not infer type arguments", mark);
        }

        var typeArgs = typeParameters.map(tp -> map.get(tp.getName()));
        return typeArgs;
    }

    private CJIRExpression handleLambdaTypeForMethodInference(CJMark mark, CJIRType parameterType, CJMark parameterMark,
            CJAstLambda lambdaAst, CJIRBinding itemBinding, Map<String, CJIRType> map) {
        var argMark = lambdaAst.getMark();
        if (!parameterType.isFunctionType()) {
            throw CJError.of("Expected " + parameterType + " but got a lambda expression", argMark, parameterMark);
        }
        var rawLambdaType = (CJIRClassType) parameterType;
        var lambdaArgc = rawLambdaType.getArgs().size() - 1;
        if (lambdaArgc != lambdaAst.getParameters().size()) {
            throw CJError.of("Expected function with " + lambdaArgc + " but got a lambda expression with "
                    + lambdaAst.getParameters().size() + " parameters", argMark, parameterMark);
        }
        var lambdaParameters = List.<CJIRAdHocVariableDeclaration>of();
        for (int j = 0; j + 1 < rawLambdaType.getArgs().size(); j++) {
            var parameterTriple = lambdaAst.getParameters().get(j);
            var mutable = parameterTriple.get2();
            var name = parameterTriple.get3();
            var rawLambdaArgType = rawLambdaType.getArgs().get(j);
            var lambdaArgType = getDeterminedTypeOrNull(itemBinding, map, rawLambdaArgType);
            if (lambdaArgType == null) {
                throw CJError.of("Could not infer type of lambda expression", argMark);
            }
            lambdaParameters.add(new CJIRAdHocVariableDeclaration(mark, mutable, name, lambdaArgType));
        }
        // Argument types of the lambda expression are known at this point. Use them to
        // determine the return type.
        enterLambdaScope(lambdaAst.isAsync());
        for (var parameter : lambdaParameters) {
            declareLocal(parameter);
        }
        var body = evalExpression(lambdaAst.getBody());
        exitLambdaScope();
        var lambdaType = new CJIRClassType(rawLambdaType.getItem(),
                List.of(lambdaParameters.map(p -> p.getVariableType()), List.of(body.getType())).flatMap(x -> x));
        return new CJIRLambda(lambdaAst, lambdaType, lambdaAst.isAsync(), lambdaParameters, body);
    }

    private CJIRType getDeterminedTypeOrNull(CJIRBinding binding, Map<String, CJIRType> map, CJIRType declaredType) {
        if (declaredType instanceof CJIRVariableType) {
            var name = ((CJIRVariableType) declaredType).getName();
            return binding.containsKey(name) ? binding.get(name) : map.getOrNull(name);
        } else {
            var type = (CJIRClassType) declaredType;
            var argtypes = List.<CJIRType>of();
            for (var arg : type.getArgs()) {
                var newArg = getDeterminedTypeOrNull(binding, map, arg);
                if (newArg == null) {
                    return null;
                }
                argtypes.add(newArg);
            }
            return new CJIRClassType(type.getItem(), argtypes);
        }
    }
}
