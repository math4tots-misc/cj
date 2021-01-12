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
            checkResultType(expression.getMark(), expectedType, actualType);
        }
        return ir;
    }

    private void checkResultType(CJMark mark, CJIRType expectedType, CJIRType actualType) {
        if (!expectedType.equals(ctx.getUnitType()) && !expectedType.equals(actualType)) {
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
                var exprs = e.getExpressions();
                if (exprs.size() == 0) {
                    return new CJIRLiteral(e, ctx.getUnitType(), CJIRLiteralKind.Unit, "");
                }
                var newExprs = List.<CJIRExpression>of();
                for (int i = 0; i + 1 < exprs.size(); i++) {
                    newExprs.add(evalUnitExpression(exprs.get(i)));
                }
                newExprs.add(evalExpressionEx(exprs.last(), a));
                exitScope();

                if (newExprs.size() == 1 && newExprs.get(0) instanceof CJIRBlock) {
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
                var exprsLimit = Math.min(args.size(), parameters.size());

                if (expectedReturnType.isPresent()) {
                    stack.add(Tuple3.of(mark, methodRef.getMethod().getReturnType(), expectedReturnType.get()));
                }

                while (map.size() < target && (stack.size() > 0 || exprs.size() < exprsLimit)) {
                    if (stack.size() == 0) {
                        // if the stack is empty but we have more arguments we can look at, use it.
                        var i = exprs.size();
                        var arg = args.get(i);
                        var parameterType = parameters.get(i).getVariableType();
                        var parameterMark = parameters.get(i).getMark();
                        CJIRExpression expr;
                        if (arg instanceof CJAstLambda) {
                            var lambdaAst = (CJAstLambda) arg;
                            expr = handleLambdaTypeForMethodInference(mark, parameterType, parameterMark, lambdaAst,
                                    itemBinding, map);
                        } else {
                            expr = evalExpression(arg);
                        }
                        exprs.add(expr);
                        stack.add(Tuple3.of(arg.getMark(), parameterType, expr.getType()));
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
                                    stack.add(Tuple3.of(variableType.getDeclaration().getMark(), typeFromBound,
                                            typeFromGiven));
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
                            stack.add(Tuple3.of(inferMark, classTypeParam.getArgs().get(i),
                                    classTypeGiven.getArgs().get(i)));
                        }
                    }
                }

                if (map.size() < target) {
                    throw CJError.of("Could not infer type arguments", mark);
                }

                var typeArgs = typeParameters.map(tp -> map.get(tp.getName()));
                return typeArgs;
            }

            private CJIRExpression handleLambdaTypeForMethodInference(CJMark mark, CJIRType parameterType,
                    CJMark parameterMark, CJAstLambda lambdaAst, CJIRBinding itemBinding, Map<String, CJIRType> map) {
                var argMark = lambdaAst.getMark();
                if (!parameterType.isFunctionType()) {
                    throw CJError.of("Expected " + parameterType + " but got a lambda expression", argMark,
                            parameterMark);
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
                var lambdaType = new CJIRClassType(rawLambdaType.getItem(), List
                        .of(lambdaParameters.map(p -> p.getVariableType()), List.of(body.getType())).flatMap(x -> x));
                return new CJIRLambda(lambdaAst, lambdaType, lambdaAst.isAsync(), lambdaParameters, body);
            }

            private CJIRType getDeterminedTypeOrNull(CJIRBinding binding, Map<String, CJIRType> map,
                    CJIRType declaredType) {
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
                return new CJIRVariableAccess(e, findLocal(e.getName(), e.getMark()));
            }

            @Override
            public CJIRExpression visitAssignment(CJAstAssignment e, Optional<CJIRType> a) {
                var target = evalAssignableTarget(e.getTarget());
                var expr = evalExpressionWithType(e.getExpression(), target.getTargetType());
                return new CJIRAssignment(e, target.getTargetType(), target, expr);
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
                }
                var rightAst = e.getRight().getOrElseDo(() -> new CJAstLiteral(e.getMark(), CJIRLiteralKind.Unit, ""));
                var right = evalExpressionWithType(rightAst, returnType);
                return new CJIRIf(e, returnType, condition, left, right);
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
                var condition = e.getCondition().map(b -> evalBoolExpression(b));
                var body = evalUnitExpression(e.getBody());
                exitScope();
                return new CJIRFor(e, ctx.getUnitType(), target, iterator, condition, body);
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
        }, a);
        return ir;
    }

    private CJIRAssignmentTarget evalDeclarableTarget(CJAstAssignmentTarget target, boolean mutable, CJIRType type) {
        return target.accept(new CJAstAssignmentTargetVisitor<CJIRAssignmentTarget, Void>() {
            @Override
            public CJIRAssignmentTarget visitName(CJAstNameAssignmentTarget t, Void a) {
                return new CJIRNameAssignmentTarget(t, mutable, t.getName(), type);
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
        }, null);
    }

    private void checkArgc(List<CJIRType> parameterTypes, List<?> exprs, CJMark mark) {
        var expected = parameterTypes.size();
        var actual = exprs.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " args but got " + actual, mark);
        }
    }
}
