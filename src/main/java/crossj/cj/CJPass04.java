package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;
import crossj.base.Tuple3;

/**
 * Pass 4
 *
 * Resolve expressions
 */
final class CJPass04 extends CJPassBaseEx {
    private final List<Map<String, CJIRLocalVariableDeclaration>> locals = List.of();

    CJPass04(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        for (var member : item.getMembers()) {
            if (member instanceof CJIRMethod) {
                handleMethod((CJIRMethod) member);
            }
        }
    }

    private void enterScope() {
        locals.add(Map.of());
    }

    private void exitScope() {
        locals.pop();
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
            throw CJError.of("Variable " + shortName + " not found", marks);
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

    private void handleMethod(CJIRMethod method) {
        if (method.getAst().getBody().isEmpty()) {
            return;
        }
        var bodyAst = method.getAst().getBody().get();
        enterScope();
        for (var parameter : method.getParameters()) {
            declareLocal(parameter);
        }
        var body = evalExpressionWithType(bodyAst, method.getReturnType());
        exitScope();
        method.setBody(body);
    }

    private CJIRExpression evalExpression(CJAstExpression expression) {
        return evalExpressionEx(expression, Optional.empty());
    }

    private CJIRExpression evalExpressionWithType(CJAstExpression expression, CJIRType type) {
        return evalExpressionEx(expression, Optional.of(type));
    }

    private CJIRExpression evalExpressionEx(CJAstExpression expression, Optional<CJIRType> a) {
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
                var exprs = e.getExpressions();
                if (exprs.size() == 0) {
                    return new CJIRLiteral(e, ctx.getUnitType(), CJIRLiteralKind.Unit, "");
                }
                var newExprs = List.<CJIRExpression>of();
                for (int i = 0; i + 1 < exprs.size(); i++) {
                    newExprs.add(evalExpressionWithType(exprs.get(i), ctx.getUnitType()));
                }
                newExprs.add(evalExpressionWithType(exprs.last(), a.get()));

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
                        var expr = evalExpression(arg);
                        exprs.add(expr);
                        stack.add(Tuple3.of(arg.getMark(), parameters.get(i).getVariableType(), expr.getType()));
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
        }, a);
        if (a.isPresent()) {
            var expectedType = a.get();
            var actualType = ir.getType();
            if (!expectedType.equals(actualType)) {
                throw CJError.of("Expected " + expectedType + " but got " + actualType, expression.getMark());
            }
        }
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

    private void checkArgc(List<CJIRType> parameterTypes, List<CJAstExpression> exprs, CJMark mark) {
        var expected = parameterTypes.size();
        var actual = exprs.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " args but got " + actual, mark);
        }
    }
}
