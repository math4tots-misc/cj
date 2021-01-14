package crossj.cj;

import crossj.base.List;

public final class CJIRAnnotationProcessor {

    public static CJIRAnnotationProcessor processItem(CJAstItemDefinition ast) {
        var proc = new CJIRAnnotationProcessor(ast.getMark(), ast.getAnnotations());
        proc.checkForItem(ast);
        return proc;
    }

    public static CJIRAnnotationProcessor processMember(CJAstItemMemberDefinition ast) {
        var proc = new CJIRAnnotationProcessor(ast.getMark(), ast.getAnnotations());
        proc.checkForMember(ast);
        return proc;
    }

    public static CJIRAnnotationProcessor processTypeParameter(CJAstTypeParameter ast) {
        var proc = new CJIRAnnotationProcessor(ast.getMark(), ast.getAnnotations());
        proc.checkForTypeParameter(ast);
        return proc;
    }

    private boolean nullable = false;
    private boolean test = false;
    private boolean generic = false;
    private boolean genericSelf = false;
    private boolean variadic = false;
    private final List<String> deriveList = List.of();

    private CJIRAnnotationProcessor(CJMark mark, List<CJAstAnnotationExpression> commands) {
        for (var command : commands) {
            exec(command);
        }
    }

    private void cannotMarkTest(CJAstNode ast) {
        if (test) {
            throw CJError.of("Only methods can be marked 'test'", ast.getMark());
        }
    }

    private void cannotMarkDerive(CJAstNode ast) {
        if (deriveList.size() > 0) {
            throw CJError.of("Only items can have derive annotations", ast.getMark());
        }
    }

    private void cannotMarkNullable(CJAstNode ast) {
        if (nullable){
            throw CJError.of(ast.getClass() + " cannot be marked nullable", ast.getMark());
        }
    }

    private void cannotMarkGeneric(CJAstNode ast) {
        if (generic){
            throw CJError.of(ast.getClass() + " cannot be marked generic", ast.getMark());
        }
    }

    private void cannotMarkGenericSelf(CJAstNode ast) {
        if (genericSelf){
            throw CJError.of(ast.getClass() + " cannot be marked genericSelf", ast.getMark());
        }
    }

    private void cannotMarkVariadic(CJAstNode ast) {
        if (variadic){
            throw CJError.of(ast.getClass() + " cannot be marked variadic", ast.getMark());
        }
    }

    private void checkForItem(CJAstItemDefinition ast) {
        cannotMarkTest(ast);
        cannotMarkGeneric(ast);
        cannotMarkGenericSelf(ast);
        cannotMarkVariadic(ast);
    }

    private void checkForMember(CJAstItemMemberDefinition ast) {
        cannotMarkDerive(ast);
        cannotMarkNullable(ast);
        if (!(ast instanceof CJAstMethodDefinition)) {
            cannotMarkTest(ast);
            cannotMarkGeneric(ast);
            cannotMarkGenericSelf(ast);
            cannotMarkVariadic(ast);
        }
    }

    private void checkForTypeParameter(CJAstTypeParameter ast) {
        cannotMarkDerive(ast);
        cannotMarkTest(ast);
        cannotMarkGenericSelf(ast);
        cannotMarkVariadic(ast);
    }

    public boolean isNullable() {
        return nullable;
    }

    public boolean isTest() {
        return test;
    }

    public boolean isGeneric() {
        return generic;
    }

    public boolean isGenericSelf() {
        return genericSelf;
    }

    public boolean isVariadic() {
        return variadic;
    }

    public List<String> getDeriveList() {
        return deriveList;
    }

    private void expectArgc(int expected, CJAstAnnotationExpression e) {
        if (e.getArgs().size() != expected) {
            throw CJError.of("Expected " + expected + " args but got " + e.getArgs().size(), e.getMark());
        }
    }

    private void exec(CJAstAnnotationExpression expression) {
        var command = expression.getName();
        switch (command) {
            case "nullable":
                expectArgc(0, expression);
                nullable = true;
                break;
            case "test":
                expectArgc(0, expression);
                test = true;
                break;
            case "generic":
                expectArgc(0, expression);
                generic = true;
                break;
            case "genericSelf":
                expectArgc(0, expression);
                genericSelf = true;
                break;
            case "variadic":
                expectArgc(0, expression);
                variadic = true;
                break;
            case "derive":
                deriveList.addAll(expression.getArgs().map(this::eval));
                break;
            default:
                throw CJError.of("Unrecognized annotation command: " + command, expression.getMark());
        }
    }

    private String eval(CJAstAnnotationExpression expression) {
        if (expression.getArgs().isEmpty()) {
            return expression.getName();
        } else {
            throw CJError.of("Unexpected annotation expression arguments", expression.getMark());
        }
    }
}
