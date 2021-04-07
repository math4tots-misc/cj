package crossj.cj;

import crossj.base.Assert;
import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;
import crossj.base.Pair;
import crossj.base.Range;
import crossj.base.Repr;
import crossj.base.Tuple3;
import crossj.base.Tuple4;
import crossj.base.Tuple5;
import crossj.books.dragon.ch03.Regex;
import crossj.cj.ast.CJAstAssignment;
import crossj.cj.ast.CJAstAssignmentTarget;
import crossj.cj.ast.CJAstAssignmentTargetVisitor;
import crossj.cj.ast.CJAstAugmentedAssignment;
import crossj.cj.ast.CJAstAwait;
import crossj.cj.ast.CJAstBlock;
import crossj.cj.ast.CJAstExpression;
import crossj.cj.ast.CJAstExpressionVisitor;
import crossj.cj.ast.CJAstFor;
import crossj.cj.ast.CJAstIf;
import crossj.cj.ast.CJAstIfNull;
import crossj.cj.ast.CJAstIs;
import crossj.cj.ast.CJAstLambda;
import crossj.cj.ast.CJAstListDisplay;
import crossj.cj.ast.CJAstLiteral;
import crossj.cj.ast.CJAstLogicalBinop;
import crossj.cj.ast.CJAstLogicalNot;
import crossj.cj.ast.CJAstMacroCall;
import crossj.cj.ast.CJAstMethodCall;
import crossj.cj.ast.CJAstNameAssignmentTarget;
import crossj.cj.ast.CJAstNullWrap;
import crossj.cj.ast.CJAstReturn;
import crossj.cj.ast.CJAstSwitch;
import crossj.cj.ast.CJAstThrow;
import crossj.cj.ast.CJAstTraitExpression;
import crossj.cj.ast.CJAstTry;
import crossj.cj.ast.CJAstTupleAssignmentTarget;
import crossj.cj.ast.CJAstTupleDisplay;
import crossj.cj.ast.CJAstTypeExpression;
import crossj.cj.ast.CJAstVariableAccess;
import crossj.cj.ast.CJAstVariableDeclaration;
import crossj.cj.ast.CJAstWhen;
import crossj.cj.ast.CJAstWhile;
import crossj.cj.ir.CJIRAdHocVariableDeclaration;
import crossj.cj.ir.CJIRAssignment;
import crossj.cj.ir.CJIRAssignmentTarget;
import crossj.cj.ir.CJIRAssignmentTargetVisitor;
import crossj.cj.ir.CJIRAugmentedAssignment;
import crossj.cj.ir.CJIRAwait;
import crossj.cj.ir.CJIRBinding;
import crossj.cj.ir.CJIRBlock;
import crossj.cj.ir.CJIRCase;
import crossj.cj.ir.CJIRExpression;
import crossj.cj.ir.CJIRField;
import crossj.cj.ir.CJIRFor;
import crossj.cj.ir.CJIRIf;
import crossj.cj.ir.CJIRIfNull;
import crossj.cj.ir.CJIRIs;
import crossj.cj.ir.CJIRIsSet;
import crossj.cj.ir.CJIRItem;
import crossj.cj.ir.CJIRJSBlob;
import crossj.cj.ir.CJIRJSStmt;
import crossj.cj.ir.CJIRLambda;
import crossj.cj.ir.CJIRListDisplay;
import crossj.cj.ir.CJIRLiteral;
import crossj.cj.ir.CJIRLiteralKind;
import crossj.cj.ir.CJIRLocalVariableDeclaration;
import crossj.cj.ir.CJIRLogicalBinop;
import crossj.cj.ir.CJIRLogicalNot;
import crossj.cj.ir.CJIRMethod;
import crossj.cj.ir.CJIRMethodCall;
import crossj.cj.ir.CJIRMethodRef;
import crossj.cj.ir.CJIRNameAssignmentTarget;
import crossj.cj.ir.CJIRNullWrap;
import crossj.cj.ir.CJIRParameter;
import crossj.cj.ir.CJIRReturn;
import crossj.cj.ir.CJIRSwitch;
import crossj.cj.ir.CJIRTag;
import crossj.cj.ir.CJIRThrow;
import crossj.cj.ir.CJIRTry;
import crossj.cj.ir.CJIRTupleAssignmentTarget;
import crossj.cj.ir.CJIRTupleDisplay;
import crossj.cj.ir.CJIRVariableAccess;
import crossj.cj.ir.CJIRVariableDeclaration;
import crossj.cj.ir.CJIRWhen;
import crossj.cj.ir.CJIRWhile;
import crossj.cj.ir.meta.CJIRClassType;
import crossj.cj.ir.meta.CJIRType;
import crossj.cj.ir.meta.CJIRVariableType;

/**
 * Pass 4
 *
 * Resolve expressions
 */
final class CJPass04 extends CJPassBaseEx {
    private final List<Map<String, CJIRLocalVariableDeclaration>> locals = List.of();
    private final List<Pair<Boolean, CJIRType>> lambdaStack = List.of();

    CJPass04(CJContext ctx) {
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

    private void enterLambdaScopeWithType(boolean isAsync, CJIRType returnType) {
        enterScope();
        lambdaStack.add(Pair.of(isAsync, returnType));
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
        Assert.that(locals.isEmpty());
        enterMethod(method);
        enterScope();
        for (var parameter : method.getParameters()) {
            declareLocal(parameter);
            if (parameter.hasDefault()) {
                var defaultAst = parameter.getAst().getDefaultExpression().get();
                var defaultExpr = evalExpressionWithType(defaultAst, parameter.getVariableType());
                parameter.setDefaultExpression(Optional.of(defaultExpr));
            }
        }
        var body = evalExpressionWithType(bodyAst, method.getInnerReturnType());
        exitScope();
        exitMethod();
        if (!locals.isEmpty()) {
            IO.println(lctx.getItem().getFullName() + "." + method.getName() + " -> " + locals);
        }
        Assert.that(locals.isEmpty());
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
            throw CJError.of("Expected a Bool convertible value but got " + actualType.repr(), expression.getMark());
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
        checkArgc(reifiedMethodRef.getName(), parameterTypes, args, ast.getMark());
        for (int i = 0; i < args.size(); i++) {
            var parameterType = parameterTypes.get(i);
            var arg = args.get(i);
            checkResultType(arg.getMark(), parameterType, arg.getType());
        }
        var returnType = reifiedMethodRef.getReturnType();
        return new CJIRMethodCall(ast, returnType, owner, reifiedMethodRef, args);
    }

    private CJIRMethodCall inferAndSynthesizeMethodCall(CJAstExpression ast, CJIRType owner, CJIRMethodRef methodRef,
            List<CJIRExpression> args, Optional<CJIRType> expectedReturnType) {
        var mark = ast.getMark();
        var typeArgs = inferMethodTypeArgs(mark, owner, methodRef, expectedReturnType, null, args);
        var reifiedMethodRef = ctx.checkMethodTypeArgs(owner, methodRef, typeArgs, ast.getMark());
        var parameterTypes = reifiedMethodRef.getParameterTypes();
        Assert.that(!methodRef.getMethod().isVariadic());
        checkArgc(reifiedMethodRef.getName(), parameterTypes, args, ast.getMark());
        for (int i = 0; i < args.size(); i++) {
            var parameterType = parameterTypes.get(i);
            var arg = args.get(i);
            checkResultType(arg.getMark(), parameterType, arg.getType());
        }
        var returnType = reifiedMethodRef.getReturnType();
        return new CJIRMethodCall(ast, returnType, owner, reifiedMethodRef, args);
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
        if (expectedType.equals(ctx.getUnitType()) && actualType.isPromiseType()) {
            // Dangling Promise
            throw CJError.of("Unused Promise (call 'done()' if result is not needed)", mark);
        } else if (expectedType.equals(ctx.getUnitType()) || actualType.equals(ctx.getNoReturnType())) {
            // when the expected type is Unit or the expression's type is NoReturn,
            // by default we forgo the check.
        } else if (!expectedType.equals(actualType)) {
            // TODO: Better type name
            throw CJError.of("Expected " + expectedType.repr() + " but got " + actualType.repr(), mark);
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
                case BigInt:
                    return new CJIRLiteral(e, ctx.getBigIntType(), e.getKind(), e.getRawText());
                }
                throw CJError.of("TODO evalExpression-visitBlock", e.getMark());
            }

            @Override
            public CJIRExpression visitBlock(CJAstBlock e, Optional<CJIRType> a) {
                enterScope();
                var noReturnType = ctx.getNoReturnType();
                var exprs = e.getExpressions();
                if (exprs.size() == 0) {
                    exitScope();
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

            private boolean isPrivateCompatible(CJAstMethodCall e, CJIRMethodRef methodRef) {
                if (e.isReceiverOmitted()) {
                    return true;
                }
                if (methodRef.getOwner().getItem() == lctx.getItem()) {
                    return true;
                }
                return false;
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

                if (methodRef.getMethod().isPrivate() && !isPrivateCompatible(e, methodRef)) {
                    var name = methodRef.getOwner().repr() + "." + methodRef.getName();
                    throw CJError.of(name + " is private and cannot be called here", e.getMark());
                }

                if (e.isReceiverOmitted()) {
                    // This is an unqualified method name.
                    // In this case, check if the first parameter is named 'self'.
                    // If so, implicitly add 'self' as the first argument
                    //
                    // Also, since ASTs can sometimes be shallow copied to multiple places,
                    // check that adding this implicit self wasn't done already.
                    //
                    Assert.that(e.getOwner().isPresent());
                    Assert.that(args.isEmpty());
                    var method = methodRef.getMethod();
                    var parameters = method.getParameters();
                    if (!parameters.isEmpty() && parameters.get(0).getName().equals("self")) {
                        if (!e.isImplicitSelfAdded()) {
                            argAsts.insert(0, new CJAstVariableAccess(e.getMark(), "self"));
                            e.setImplicitSelfAdded(true);
                        }
                    }
                }

                // The returned method call might be used with an implicit method call
                // to account for that, we preemptively check here whether the conditions
                // are ripe for a conversion method call. And if so, we see if it's possible
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
                checkArgcEx(e.getName(), parameterTypes, reifiedMethodRef.getMethodRef().getMethod().getParameters(),
                        argAsts, e.getMark());
                while (args.size() < argAsts.size()) {
                    var parameterType = parameterTypes.get(args.size());
                    var argAst = argAsts.get(args.size());
                    args.add(evalExpressionWithType(argAst, parameterType));
                }
                var returnType = reifiedMethodRef.getReturnType();
                return new CJIRMethodCall(e, returnType, owner, reifiedMethodRef, args);
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
                var name = e.getVariableName();
                var decl = findLocalOrNull(name);
                if (decl == null) {
                    // Check for Self.* and self.* variables
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
                                throw CJError.of(
                                        "Non-static field " + name + " cannot be assigned without a 'self' in scope",
                                        e.getMark());
                            }
                            return evalUnitExpression(new CJAstMethodCall(e.getMark(),
                                    Optional.of(new CJAstTypeExpression(e.getMark(), "Self", List.of())),
                                    "__set_" + name, List.of(),
                                    List.of(new CJAstVariableAccess(e.getMark(), "self"), e.getExpression())));
                        }
                    }
                    throw CJError.of("Variable " + Repr.of(name) + " not found", e.getMark());
                }
                if (!decl.isMutable()) {
                    throw CJError.of(name + " is not mutable", decl.getMark());
                }
                var expr = evalExpressionWithType(e.getExpression(), decl.getVariableType());
                return new CJIRAssignment(e, ctx.getUnitType(), name, expr);
            }

            @Override
            public CJIRExpression visitAugmentedAssignment(CJAstAugmentedAssignment e, Optional<CJIRType> a) {
                var name = e.getTarget();
                var target = findLocalOrNull(name);
                if (target != null) {
                    var targetType = target.getVariableType();
                    if (targetType.equals(ctx.getIntType()) || targetType.equals(ctx.getDoubleType())) {
                        var expression = evalExpressionWithType(e.getExpression(), target.getVariableType());
                        return new CJIRAugmentedAssignment(e, ctx.getUnitType(), target, e.getKind(), expression);
                    } else {
                        throw CJError.of("Augmented assignments are only supported for int and double values",
                                e.getMark());
                    }
                }
                var selfType = lctx.getSelfType();
                var methodRef = selfType.findMethodOrNull("__get_" + name);
                if (methodRef != null) {
                    var method = methodRef.getMethod();
                    String augMethodName = "";
                    switch (e.getKind()) {
                    case Add:
                        augMethodName = "__add";
                        break;
                    case Subtract:
                        augMethodName = "__sub";
                        break;
                    case Multiply:
                        augMethodName = "__mul";
                        break;
                    case Remainder:
                        augMethodName = "__rem";
                        break;
                    }
                    Assert.notEquals(augMethodName, "");
                    if (method.getParameters().size() == 0) {
                        var getExpr = new CJAstMethodCall(e.getMark(),
                                Optional.of(new CJAstTypeExpression(e.getMark(), "Self", List.of())), "__get_" + name,
                                List.of(), List.of());
                        var augExpr = new CJAstMethodCall(e.getMark(), Optional.empty(), augMethodName, List.of(),
                                List.of(getExpr, e.getExpression()));
                        var setExpr = new CJAstMethodCall(e.getMark(),
                                Optional.of(new CJAstTypeExpression(e.getMark(), "Self", List.of())), "__set_" + name,
                                List.of(), List.of(augExpr));
                        return evalUnitExpression(setExpr);
                    } else if (method.getParameters().size() == 1) {
                        var selfDecl = findLocalOrNull("self");
                        if (selfDecl == null) {
                            throw CJError.of(
                                    "Non-static field " + name + " cannot be aug-assigned without a 'self' in scope",
                                    e.getMark());
                        }
                        var selfExpr = new CJAstVariableAccess(e.getMark(), "self");
                        var getExpr = new CJAstMethodCall(e.getMark(),
                                Optional.of(new CJAstTypeExpression(e.getMark(), "Self", List.of())), "__get_" + name,
                                List.of(), List.of(selfExpr));
                        var augExpr = new CJAstMethodCall(e.getMark(), Optional.empty(), augMethodName, List.of(),
                                List.of(getExpr, e.getExpression()));
                        var setExpr = new CJAstMethodCall(e.getMark(),
                                Optional.of(new CJAstTypeExpression(e.getMark(), "Self", List.of())), "__set_" + name,
                                List.of(), List.of(selfExpr, augExpr));
                        return evalUnitExpression(setExpr);
                    }
                }
                throw CJError.of("Variable " + name + " not found", e.getMark());
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
                            throw CJError.of("Expected " + expectedType.repr() + " but got a nullable expression",
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
                        throw CJError.of("Expected " + expectedType.repr() + " but got a list display", e.getMark());
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
                        CJIRItem tupleItem;
                        switch (e.getExpressions().size()) {
                        case 2:
                            tupleItem = ctx.getTuple2Item();
                            break;
                        case 3:
                            tupleItem = ctx.getTuple3Item();
                            break;
                        case 4:
                            tupleItem = ctx.getTuple4Item();
                            break;
                        default:
                            throw CJError.of("Tuple 2, 3, or 4 expected but got " + e.getExpressions().size(),
                                    e.getMark());
                        }
                        var newExpectedType = getNewExpectedTypeBasedOnImplicits(e.getMark(), a.get(), tupleItem);
                        if (newExpectedType.isPresent()) {
                            expectedType = newExpectedType.get();
                            Assert.that(expectedType.isTupleType());
                        } else {
                            throw CJError.of("Expected " + expectedType + " but got a tuple display", e.getMark());
                        }
                    }
                    var displayItemName = "cj.Tuple" + e.getExpressions().size();
                    var classType = (CJIRClassType) expectedType;
                    if (!classType.getItem().getFullName().equals(displayItemName)) {
                        throw CJError.of("Expected " + classType.repr() + " but got a " + displayItemName, e.getMark());
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
                return new CJIRWhile(e, condition.isAlwaysTrue() ? ctx.getNoReturnType() : unitType, condition, body);
            }

            @Override
            public CJIRExpression visitFor(CJAstFor e, Optional<CJIRType> a) {
                var container = evalExpression(e.getContainer());
                var iterable = container.getType().getImplementingTraitByItemOrNull(ctx.getIterableItem());
                if (iterable == null) {
                    throw CJError.of("For loop requires an iterable, but got " + container.getType().repr(),
                            e.getMark());
                }
                var methodRef = container.getType().findMethod("iter", e.getMark());
                var iterator = synthesizeMethodCall(e, container.getType(), methodRef, List.of(), List.of(container));
                var targetType = iterable.getArgs().get(0);
                enterScope();
                var target = evalDeclarableTarget(e.getTarget(), false, targetType);
                declareTarget(target);
                var body = evalUnitExpression(e.getBody());
                exitScope();
                return new CJIRFor(e, ctx.getUnitType(), target, iterator, body);
            }

            @Override
            public CJIRExpression visitWhen(CJAstWhen e, Optional<CJIRType> a) {
                var target = evalExpression(e.getTarget());
                if (!target.getType().isUnionType()) {
                    throw CJError.of(target.getType().repr() + " is not a union type", target.getMark());
                }
                var type = (CJIRClassType) target.getType();
                var bindings = type.getBindingWithSelfType(type);
                var casesByTag = type.getItem().getCases();
                var caseNamesByTag = casesByTag.map(defn -> defn.getName());
                var caseTypesByTag = casesByTag.map(defn -> defn.getTypes().map(bindings::apply));
                var caseTagsByName = Map
                        .fromIterable(Range.upto(casesByTag.size()).map(i -> Pair.of(caseNamesByTag.get(i), i)));
                var sieve = Range.upto(caseTypesByTag.size()).map(i -> false).list();
                var cases = List
                        .<Tuple5<CJMark, CJIRCase, List<CJIRAdHocVariableDeclaration>, Boolean, CJIRExpression>>of();
                for (var caseAst : e.getCases()) {
                    var patternAsts = caseAst.get1();
                    var caseBody = caseAst.get2();
                    for (var patternAst : patternAsts) {
                        var caseMark = patternAst.get1();
                        var caseName = patternAst.get2();
                        var caseVars = patternAst.get3();
                        var trailingArgs = patternAst.get4();
                        var tag = caseTagsByName.getOrNull(caseName);
                        if (tag == null) {
                            throw CJError.of(caseName + " is not a case in " + type.repr(), caseMark);
                        }
                        if (sieve.get(tag)) {
                            throw CJError.of("Duplicate entry for " + caseName, caseMark);
                        }
                        sieve.set(tag, true);
                        var caseDefn = casesByTag.get(tag);
                        if (trailingArgs) {
                            if (caseDefn.getTypes().size() < caseVars.size()) {
                                throw CJError.of(caseName + " only has " + caseDefn.getTypes().size()
                                        + " values but got " + caseVars.size() + " names", caseMark);
                            }
                        } else {
                            if (caseDefn.getTypes().size() != caseVars.size()) {
                                throw CJError.of(caseName + " expects " + caseDefn.getTypes().size() + " args but got "
                                        + caseVars.size(), caseMark);
                            }
                        }
                        var caseTypes = caseDefn.getTypes().map(bindings::apply);
                        var vars = Range.upto(caseVars.size()).map(i -> {
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
                        cases.add(Tuple5.of(caseMark, caseDefn, vars, trailingArgs, body));
                    }
                }
                for (var elseCaseAst : e.getElseCases()) {
                    var caseBody = elseCaseAst.get2();
                    for (var patternAst : elseCaseAst.get1()) {
                        var caseMark = patternAst.getMark();
                        var caseNameVar = patternAst.getCaseNameVar();
                        var caseVars = patternAst.getDecls();
                        var trailingArgs = patternAst.isVariadic();
                        var matchFound = false;
                        for (int tag = 0; tag < casesByTag.size(); tag++) {
                            if (sieve.get(tag)) {
                                // skip cases we've already covered
                                continue;
                            }
                            if (trailingArgs) {
                                if (casesByTag.get(tag).getTypes().size() < caseVars.size()) {
                                    continue;
                                }
                            } else if (casesByTag.get(tag).getTypes().size() != caseVars.size()) {
                                continue;
                            }
                            matchFound = true;
                            var caseName = casesByTag.get(tag).getName();
                            sieve.set(tag, true);
                            var caseDefn = casesByTag.get(tag);
                            var caseTypes = caseDefn.getTypes().map(bindings::apply);
                            var vars = Range.upto(caseVars.size()).map(i -> {
                                var varAst = caseVars.get(i);
                                var varMark = varAst.get1();
                                var mutable = varAst.get2();
                                var varName = varAst.get3();
                                var varType = caseTypes.get(i);
                                return new CJIRAdHocVariableDeclaration(varMark, mutable, varName, varType);
                            }).list();
                            enterScope();
                            vars.forEach(t -> declareLocal(t));
                            var patternBody = caseBody;
                            if (caseNameVar.isPresent()) {
                                patternBody = new CJAstBlock(caseMark,
                                        List.<CJAstExpression>of(
                                                new CJAstVariableDeclaration(caseMark, false,
                                                        new CJAstNameAssignmentTarget(caseMark, caseNameVar.get()),
                                                        Optional.empty(), new CJAstLiteral(caseMark,
                                                                CJIRLiteralKind.String, "\"" + caseName + "\"")),
                                                caseBody));
                            }
                            var body = evalExpressionEx(patternBody, a);
                            exitScope();
                            if (a.isEmpty()) {
                                a = Optional.of(body.getType());
                            }
                            cases.add(Tuple5.of(caseMark, caseDefn, vars, trailingArgs, body));
                        }
                        if (!matchFound) {
                            throw CJError.of("Else pattern with no matching cases", caseMark);
                        }
                    }
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
                return new CJIRWhen(e, a.get(), target, cases, fallback);
            }

            @Override
            public CJIRExpression visitSwitch(CJAstSwitch e, Optional<CJIRType> a) {
                var target = evalExpression(e.getTarget());
                var targetType = target.getType();
                var switchPermittedTypes = List.of(ctx.getIntType(), ctx.getCharType(), ctx.getStringType());
                // TODO: Reconsider this
                if (!switchPermittedTypes.contains(targetType)) {
                    throw CJError.of(targetType.repr() + " may not be used in a switch", e.getMark());
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
                    throw CJError.of("Expected " + type.repr() + " but got a lambda expression", e.getMark());
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
                if (e.isAsync()) {
                    enterLambdaScope(e.isAsync());
                } else {
                    enterLambdaScopeWithType(e.isAsync(), returnType);
                }
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
                var optionalExpectedInnerType = a.map(t -> ctx.getPromiseType(t, e.getMark()));
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

            private List<CJIRField> getMatchingStaticFields(CJIRClassType ownerType, Regex re) {
                var ret = List.<CJIRField>of();
                for (var field : ownerType.getItem().getFields()) {
                    if (field.isStatic() && re.matches(field.getName())) {
                        ret.add(field);
                    }
                }
                return ret;
            }

            @Override
            public CJIRExpression visitMacroCall(CJAstMacroCall e, Optional<CJIRType> a) {
                switch (e.getName()) {
                case "tag_names!": {
                    if (e.getArgs().size() != 1) {
                        throw CJError.of("tag_names! requires exactly 1 argument (owner-type)", e.getMark());
                    }
                    var target = solveExprForUnionType(e.getArgs().get(0));
                    return listOfStrings(e, target.getItem().getCases().map(c -> c.getName()));
                }
                case "tag_name!": {
                    if (e.getArgs().size() != 1) {
                        throw CJError.of("tag_name! requires exactly 1 argument", e.getMark());
                    }
                    var target = evalExpression(e.getArgs().get(0));
                    if (!target.getType().isUnionType()) {
                        throw CJError.of(target.getType().repr() + " is not a union type", target.getMark());
                    }
                    var switchTarget = new CJAstMacroCall(e.getMark(), "tag!", List.of(e.getArgs().get(0)));
                    List<Pair<List<CJAstExpression>, CJAstExpression>> cases = List.of();
                    for (var case_ : ((CJIRClassType) target.getType()).getItem().getCases()) {
                        cases.add(Pair.of(
                                List.of(new CJAstLiteral(e.getMark(), CJIRLiteralKind.Int, "" + case_.getTag())),
                                new CJAstLiteral(e.getMark(), CJIRLiteralKind.String, "\"" + case_.getName() + "\"")));
                    }
                    return evalExpressionWithType(new CJAstSwitch(e.getMark(), switchTarget, cases, Optional.empty()),
                            ctx.getStringType());
                }
                case "tag!": {
                    if (e.getArgs().size() != 1 && e.getArgs().size() != 2) {
                        throw CJError.of("tag! requires 1 or 2 arguments", e.getMark());
                    }
                    if (e.getArgs().size() == 1) {
                        var target = evalExpression(e.getArgs().get(0));
                        if (!target.getType().isUnionType()) {
                            throw CJError.of(target.getType().repr() + " is not a union type", target.getMark());
                        }
                        return new CJIRTag(e, ctx.getIntType(), target);
                    } else {
                        Assert.equals(e.getArgs().size(), 2);
                        var type = solveExprForUnionType(e.getArgs().get(0));
                        var name = solveExprForName(e.getArgs().get(1));
                        for (var case_ : type.getItem().getCases()) {
                            if (case_.getName().equals(name)) {
                                return intExpr(e, case_.getTag());
                            }
                        }
                        throw CJError.of("Tag name " + name + " not found", e.getMark());
                    }
                }
                case "static_field_names!": {
                    if (e.getArgs().size() != 2) {
                        throw CJError.of(
                                "static_field_names! requires exactly 2 arguments " + "(owner-type, strlit-regex)",
                                e.getMark());
                    }
                    var ownerType = solveExprForClassType(e.getArgs().get(0));
                    var re = solveExprForRegex(e.getArgs().get(1));
                    return listOfStrings(e, getMatchingStaticFields(ownerType, re).map(f -> f.getName()));
                }
                case "static_field_values!": {
                    if (e.getArgs().size() != 2) {
                        throw CJError.of(
                                "static_field_names! requires exactly 2 arguments " + "(owner-type, strlit-regex)",
                                e.getMark());
                    }
                    var ownerType = solveExprForClassType(e.getArgs().get(0));
                    var ownerTypeExpr = solveExprForTypeExpression(e.getArgs().get(0));
                    var re = solveExprForRegex(e.getArgs().get(1));
                    var subexprs = List.<CJAstExpression>of();
                    for (var field : getMatchingStaticFields(ownerType, re)) {
                        var name = field.getName();
                        if (re.matches(name)) {
                            var getterName = field.getGetterName();
                            subexprs.add(new CJAstMethodCall(e.getMark(), Optional.of(ownerTypeExpr), getterName,
                                    List.of(), List.of()));
                        }
                    }
                    return evalExpressionEx(new CJAstListDisplay(e.getMark(), subexprs), a);
                }
                case "static_field_name_value_pairs!": {
                    if (e.getArgs().size() != 2) {
                        throw CJError.of(
                                "static_field_names! requires exactly 2 arguments " + "(owner-type, strlit-regex)",
                                e.getMark());
                    }
                    var ownerType = solveExprForClassType(e.getArgs().get(0));
                    var ownerTypeExpr = solveExprForTypeExpression(e.getArgs().get(0));
                    var re = solveExprForRegex(e.getArgs().get(1));
                    var subexprs = List.<CJAstExpression>of();
                    for (var field : getMatchingStaticFields(ownerType, re)) {
                        var name = field.getName();
                        if (re.matches(name)) {
                            var getterName = field.getGetterName();
                            var nameExpr = new CJAstLiteral(e.getMark(), CJIRLiteralKind.String, "\"" + name + "\"");
                            subexprs.add(new CJAstTupleDisplay(e.getMark(),
                                    List.of(nameExpr, new CJAstMethodCall(e.getMark(), Optional.of(ownerTypeExpr),
                                            getterName, List.of(), List.of()))));
                        }
                    }
                    return evalExpressionEx(new CJAstListDisplay(e.getMark(), subexprs), a);
                }
                case "is_set!": {
                    // Checks if a lateinit field has had its value set yet.
                    if (e.getArgs().size() != 2) {
                        throw CJError.of("is_set! requires exactly 2 arguments (owner, field-name)", e.getMark());
                    }
                    var fieldName = solveExprForName(e.getArgs().get(1));
                    CJIRClassType ownerType;
                    Optional<CJIRExpression> optOwner;

                    if (e.getArgs().get(0) instanceof CJAstTypeExpression) {
                        // static fields
                        ownerType = solveExprForClassType(e.getArgs().get(0));
                        optOwner = Optional.empty();
                    } else {
                        // instance fields
                        var owner = evalExpression(e.getArgs().get(0));
                        optOwner = Optional.of(owner);
                        if (!(owner.getType() instanceof CJIRClassType)) {
                            throw CJError.of("is_set! requires a class type", e.getMark());
                        }
                        ownerType = (CJIRClassType) owner.getType();
                    }
                    var field = ownerType.getItem().findFieldOrNull(fieldName);
                    if (field == null) {
                        throw CJError.of("Field " + fieldName + " not found in " + ownerType.repr(), e.getMark());
                    }
                    if (field.isStatic()) {
                        if (optOwner.isPresent()) {
                            throw CJError.of(fieldName + " is a static field", e.getMark());
                        }
                    } else {
                        if (optOwner.isEmpty()) {
                            throw CJError.of(fieldName + " is a non-static field", e.getMark());
                        }
                    }
                    if (!field.isLateinit()) {
                        throw CJError.of(fieldName + " is not a lateinit field", e.getMark());
                    }
                    return new CJIRIsSet(e, ctx.getBoolType(), ownerType, optOwner, field);
                }
                case "get!": {
                    // Get a value from a union element, asserting a specific case.
                    if (e.getArgs().size() != 3) {
                        throw CJError.of("get! requires exactly 3 arguments (owner, case-name, index)", e.getMark());
                    }
                    var mark = e.getMark();
                    var target = e.getArgs().get(0);
                    var caseName = solveExprForName(e.getArgs().get(1));
                    var index = solveExprForInt(e.getArgs().get(2));
                    var expr = new CJAstWhen(
                            mark, target, List
                                    .of(Pair.of(
                                            List.of(Tuple4.of(mark, caseName,
                                                    Range.upto(index + 1).map(i -> Tuple3.of(mark, false, "a" + i))
                                                            .list(),
                                                    true)),
                                            new CJAstVariableAccess(mark, "a" + index))),
                            List.of(),
                            Optional.of(new CJAstMethodCall(mark,
                                    Optional.of(new CJAstTypeExpression(mark, "IO", List.of())), "panic", List.of(),
                                    List.of(new CJAstLiteral(mark, CJIRLiteralKind.String, "\"get! match failed\"")))));
                    return evalExpressionEx(expr, a);
                }
                case "include_str!": {
                    if (e.getArgs().size() != 1) {
                        throw CJError.of("include_str! requires exactly 1 argument (strlit)", e.getMark());
                    }
                    var relpath = solveExprForStringLiteral(e.getArgs().get(0));
                    var path = getPathGivenRelpath(e.getMark(), relpath);
                    var contents = IO.readFile(path);
                    return evalExpression(new CJAstLiteral(e.getMark(), CJIRLiteralKind.String, Repr.of(contents)));
                }
                case "include_bytes!": {
                    if (e.getArgs().size() != 1) {
                        throw CJError.of("include_bytes! requires exactly 1 argument (strlit)", e.getMark());
                    }
                    var relpath = solveExprForStringLiteral(e.getArgs().get(0));
                    var path = getPathGivenRelpath(e.getMark(), relpath);
                    var contents = IO.readFileBytes(path);
                    var sb = new StringBuilder();
                    sb.append("stringToArrayBuffer(\"");
                    for (int i = 0; i < contents.size(); i++) {
                        var value = contents.getU8(i);
                        if (value == 0) {
                            sb.append("\\0");
                        } else if (value == '\\' || value == '"') {
                            sb.append('\\');
                            sb.append((char) value);
                        } else if (value >= ' ' && value <= '~') {
                            sb.append((char) value);
                        } else {
                            sb.append("\\x" + String.format("%02x", value));
                        }
                    }
                    sb.append("\")");
                    var arrbuftype = ctx.getTypeWithArgs("cj.ArrayBuffer", List.of(), e.getMark());
                    return new CJIRJSBlob(e, arrbuftype, List.of(sb.toString()));
                }
                case "listdir!": {
                    if (e.getArgs().size() != 1) {
                        throw CJError.of("listdir! requires exactly 1 argument (strlit)", e.getMark());
                    }
                    var rawpath = solveExprForStringLiteral(e.getArgs().get(0));
                    var dirpath = IO.join(IO.dirname(e.getMark().filename), rawpath);
                    return listOfStrings(e, FS.list(dirpath));
                }
                case "js!": {
                    if (e.getArgs().size() < 2) {
                        throw CJError.of("js! requires at least 2 arguments (Type, strlit|Expr...)", e.getMark());
                    }
                    var type = solveExprForType(e.getArgs().get(0));
                    var parts = List.<Object>of();
                    for (int i = 1; i < e.getArgs().size(); i++) {
                        var expr = e.getArgs().get(i);
                        var optstrlit = solveExprForStringLiteralOrEmpty(expr);
                        if (optstrlit.isPresent()) {
                            parts.add(optstrlit.get());
                        } else {
                            parts.add(evalExpression(expr));
                        }
                    }
                    return new CJIRJSBlob(e, type, parts);
                }
                case "js0!": {
                    // Like js!, but the return type is inferred
                    if (e.getArgs().size() < 1) {
                        throw CJError.of("js0! requires at least 1 argument (strlit|Expr...)", e.getMark());
                    }
                    if (a.isEmpty()) {
                        throw CJError.of("Could not determine return type of js0!", e.getMark());
                    }
                    var type = a.get();
                    var parts = List.<Object>of();
                    for (int i = 0; i < e.getArgs().size(); i++) {
                        var expr = e.getArgs().get(i);
                        var optstrlit = solveExprForStringLiteralOrEmpty(expr);
                        if (optstrlit.isPresent()) {
                            parts.add(optstrlit.get());
                        } else {
                            parts.add(evalExpression(expr));
                        }
                    }
                    return new CJIRJSBlob(e, type, parts);
                }
                case "jsm!": {
                    if (e.getArgs().size() < 3) {
                        throw CJError.of("jsm! requires at least 3 arguments (Type, recv, strlit, Expr...)",
                                e.getMark());
                    }
                    var type = solveExprForType(e.getArgs().get(0));
                    var parts = List.<Object>of();
                    parts.add(evalExpression(e.getArgs().get(1))); // receiver
                    parts.add("." + solveExprForStringLiteral(e.getArgs().get(2)) + "("); // method name
                    for (int i = 3; i < e.getArgs().size(); i++) {
                        if (i > 3) {
                            parts.add(",");
                        }
                        var expr = e.getArgs().get(i);
                        parts.add(evalExpression(expr));
                    }
                    parts.add(")");
                    return new CJIRJSBlob(e, type, parts);
                }
                case "jsm0!": {
                    if (e.getArgs().size() < 2) {
                        throw CJError.of("jsm0! requires at least 2 arguments (recv, strlit, Expr...)", e.getMark());
                    }
                    if (a.isEmpty()) {
                        throw CJError.of("Could not determine return type of jsm0!", e.getMark());
                    }
                    var type = a.get();
                    var parts = List.<Object>of();
                    parts.add(evalExpression(e.getArgs().get(0))); // receiver
                    parts.add("." + solveExprForStringLiteral(e.getArgs().get(1)) + "("); // method name
                    for (int i = 2; i < e.getArgs().size(); i++) {
                        if (i > 2) {
                            parts.add(",");
                        }
                        var expr = e.getArgs().get(i);
                        parts.add(evalExpression(expr));
                    }
                    parts.add(")");
                    return new CJIRJSBlob(e, type, parts);
                }
                case "js_stmt!": {
                    if (e.getArgs().size() != 1) {
                        throw CJError.of("js_stmt! requires exactly 1 argument (strlit)", e.getMark());
                    }
                    var content = solveExprForStringLiteral(e.getArgs().get(0));
                    return new CJIRJSStmt(e, ctx.getUnitType(), content);
                }
                case "json!": {
                    var jsonobjtype = ctx.getTypeWithArgs("cj.JSON", List.of(), e.getMark());
                    var parts = List.<Object>of();
                    parts.add("{");
                    for (int i = 0; i < e.getArgs().size(); i++) {
                        if (i > 0) {
                            parts.add(",");
                        }
                        var pair = solveExprForPair(e.getArgs().get(i));
                        var key = solveExprForNameOrStringLiteral(pair.get1());
                        var value = evalExpressionWithType(pair.get2(), jsonobjtype);
                        parts.add(key + ":");
                        parts.add(value);
                    }
                    parts.add("}");
                    return new CJIRJSBlob(e, jsonobjtype, parts);
                }
                case "jsobj!": {
                    var jsobjtype = ctx.getTypeWithArgs("www.JSObject", List.of(), e.getMark());
                    var parts = List.<Object>of();
                    parts.add("{");
                    for (int i = 0; i < e.getArgs().size(); i++) {
                        if (i > 0) {
                            parts.add(",");
                        }
                        var pair = solveExprForPair(e.getArgs().get(i));
                        var key = solveExprForNameOrStringLiteral(pair.get1());
                        var value = evalExpressionWithType(pair.get2(), jsobjtype);
                        parts.add(key + ":");
                        parts.add(value);
                    }
                    parts.add("}");
                    return new CJIRJSBlob(e, jsobjtype, parts);
                }
                default:
                    throw CJError.of("Unrecognized macro " + Repr.of(e.getName()), e.getMark());
                }
            }

            @Override
            public CJIRExpression visitType(CJAstTypeExpression e, Optional<CJIRType> a) {
                throw CJError.of("Expected expression but got type", e.getMark());
            }

            @Override
            public CJIRExpression visitTrait(CJAstTraitExpression e, Optional<CJIRType> a) {
                throw CJError.of("Expected expression but got trait", e.getMark());
            }
        }, a);
        return ir;
    }

    private CJIRExpression intExpr(CJAstExpression ast, int value) {
        return new CJIRLiteral(ast, ctx.getIntType(), CJIRLiteralKind.Int, "" + value);
    }

    private CJIRExpression listOfStrings(CJAstExpression ast, List<String> strings) {
        var subexprs = List.<CJIRExpression>of();
        for (var string : strings) {
            Assert.that(!string.contains("\""));
            Assert.that(!string.contains("\\"));
            subexprs.add(new CJIRLiteral(ast, ctx.getStringType(), CJIRLiteralKind.String, "\"" + string + "\""));
        }
        return new CJIRListDisplay(ast, ctx.getListType(ctx.getStringType()), subexprs);
    }

    private Pair<CJAstExpression, CJAstExpression> solveExprForPair(CJAstExpression expr) {
        var pair = solveExprForPairOrNull(expr);
        if (pair == null) {
            throw CJError.of("Expected pair here", expr.getMark());
        }
        return pair;
    }

    private Pair<CJAstExpression, CJAstExpression> solveExprForPairOrNull(CJAstExpression expr) {
        if (!(expr instanceof CJAstTupleDisplay)) {
            return null;
        }
        var tuple = (CJAstTupleDisplay) expr;
        if (tuple.getExpressions().size() != 2) {
            return null;
        }
        return Pair.of(tuple.getExpressions().get(0), tuple.getExpressions().get(1));
    }

    private CJIRClassType solveExprForUnionType(CJAstExpression expr) {
        var t = solveExprForClassType(expr);
        if (!t.isUnionType()) {
            throw CJError.of("Expected union type expression here", expr.getMark());
        }
        return t;
    }

    private CJIRClassType solveExprForClassType(CJAstExpression expr) {
        var t = solveExprForType(expr);
        if (!(t instanceof CJIRClassType)) {
            throw CJError.of("Expected class type expression here", expr.getMark());
        }
        return (CJIRClassType) t;
    }

    private CJAstTypeExpression solveExprForTypeExpression(CJAstExpression expr) {
        if (!(expr instanceof CJAstTypeExpression)) {
            throw CJError.of("Expected type expression here", expr.getMark());
        }
        return (CJAstTypeExpression) expr;
    }

    private CJIRType solveExprForType(CJAstExpression expr) {
        if (!(expr instanceof CJAstTypeExpression)) {
            throw CJError.of("Expected type expression here", expr.getMark());
        }
        return lctx.evalTypeExpression((CJAstTypeExpression) expr);
    }

    private static String solveExprForNameOrStringLiteral(CJAstExpression expr) {
        var name = solveExprForNameOrNull(expr);
        if (name != null) {
            return name;
        }
        var optlit = solveExprForStringLiteralOrEmpty(expr);
        if (optlit.isPresent()) {
            return optlit.get();
        }
        throw CJError.of("Expected name or string literal here", expr.getMark());
    }

    private static String solveExprForNameOrNull(CJAstExpression expr) {
        if (expr instanceof CJAstVariableAccess) {
            return ((CJAstVariableAccess) expr).getName();
        } else {
            return null;
        }
    }

    private static String solveExprForName(CJAstExpression expr) {
        var name = solveExprForNameOrNull(expr);
        if (name == null) {
            throw CJError.of("Expected name", expr.getMark());
        }
        return name;
    }

    private static Integer solveExprForIntOrNull(CJAstExpression expr) {
        if (expr instanceof CJAstLiteral) {
            var lit = (CJAstLiteral) expr;
            switch (lit.getKind()) {
            case Int:
                return Integer.parseInt(lit.getRawText());
            default:
                return null;
            }
        } else {
            return null;
        }
    }

    private static int solveExprForInt(CJAstExpression expr) {
        var i = solveExprForIntOrNull(expr);
        if (i != null) {
            return i;
        } else {
            throw CJError.of("Expected int literal", expr.getMark());
        }
    }

    private static Regex solveExprForRegex(CJAstExpression expr) {
        var pattern = solveExprForStringLiteral(expr);
        var tryRe = Regex.fromPatterns(pattern);
        if (tryRe.isFail()) {
            throw CJError.of("Failed to parse regex: " + tryRe.getErrorMessage(), expr.getMark());
        }
        return tryRe.get();
    }

    private static String solveExprForStringLiteral(CJAstExpression expr) {
        var optString = solveExprForStringLiteralOrEmpty(expr);
        if (optString.isEmpty()) {
            throw CJError.of("Expected string literal here", expr.getMark());
        }
        return optString.get();
    }

    private static Optional<String> solveExprForStringLiteralOrEmpty(CJAstExpression expr) {
        if (expr instanceof CJAstLiteral) {
            var literal = (CJAstLiteral) expr;
            switch (literal.getKind()) {
            case String:
                return Optional.of(Repr.parse(literal.getRawText()));
            default:
                break;
            }
        }
        if (expr instanceof CJAstMacroCall) {
            var mcall = (CJAstMacroCall) expr;
            switch (mcall.getName()) {
            case "include_str!": {
                if (mcall.getArgs().size() != 1) {
                    throw CJError.of("include_str! requires exactly 1 argument (strlit)", mcall.getMark());
                }
                var relpath = solveExprForStringLiteral(mcall.getArgs().get(0));
                var path = getPathGivenRelpath(mcall.getMark(), relpath);
                var contents = IO.readFile(path);
                return Optional.of(contents);
            }
            default:
                break;
            }
        }
        return Optional.empty();
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

    private void checkArgc(String name, List<CJIRType> parameterTypes, List<?> exprs, CJMark mark) {
        var expected = parameterTypes.size();
        var actual = exprs.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " args but got " + actual + " for " + name, mark);
        }
    }

    private void checkArgcEx(String name, List<CJIRType> parameterTypes, List<CJIRParameter> parameters, List<?> exprs,
            CJMark mark) {
        var expectedMax = parameterTypes.size();
        int expectedMin = parameters.size();
        while (expectedMin > 0 && parameters.get(expectedMin - 1).hasDefault()) {
            expectedMin--;
        }
        var actual = exprs.size();
        if (expectedMin == expectedMax) {
            var expected = expectedMin;
            if (expected != actual) {
                throw CJError.of("Expected " + expected + " args but got " + actual + " for " + name, mark);
            }
        } else {
            if (actual < expectedMin || actual > expectedMax) {
                throw CJError.of(
                        "Expected " + expectedMin + " to " + expectedMax + " args but got " + actual + " for " + name,
                        mark);
            }
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
                            throw CJError.of(given.repr() + " does not implement required bound " + bound.repr(),
                                    inferMark, variableType.getDeclaration().getMark());
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
                    // Just skip it for now. If this is actually invalid, this should be caught
                    // later down the line.
                    // Also throwing an error here prevents autocasting (e.g. providing a Char
                    // when an Int is expected)

                    // throw CJError.of("Expected argument of form " + param.repr() + " but got " +
                    // given.repr(),
                    // inferMark);
                } else {
                    for (int i = 0; i < classTypeGiven.getArgs().size(); i++) {
                        stack.add(
                                Tuple3.of(inferMark, classTypeParam.getArgs().get(i), classTypeGiven.getArgs().get(i)));
                    }
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

    private static String getPathGivenRelpath(CJMark mark, String relpath) {
        var path = IO.join(IO.dirname(mark.filename), relpath);
        if (!FS.isFile(path)) {
            throw CJError.of("File " + path + " not found", mark);
        }
        return path;
    }
}
