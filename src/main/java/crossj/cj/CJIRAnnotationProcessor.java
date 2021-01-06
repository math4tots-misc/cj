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

    private boolean test = false;
    private final List<String> deriveList = List.of();

    private CJIRAnnotationProcessor(CJMark mark, List<CJAstAnnotationExpression> commands) {
        for (var command : commands) {
            exec(command);
        }
    }

    private void checkForItem(CJAstItemDefinition ast) {
        if (test) {
            throw CJError.of("Only methods can be marked 'test'", ast.getMark());
        }
    }

    private void checkForMember(CJAstItemMemberDefinition ast) {
        var mark = ast.getMark();
        if (ast instanceof CJAstMethodDefinition) {
            if (deriveList.size() > 0) {
                throw CJError.of("Methods cannot have 'derive' annotations", mark);
            }
        }
    }

    public boolean isTest() {
        return test;
    }

    public List<String> getDeriveList() {
        return deriveList;
    }

    private void exec(CJAstAnnotationExpression expression) {
        var command = expression.getName();
        switch (command) {
            case "test":
                if (expression.getArgs().size() > 0) {
                    throw CJError.of("Unexpected annotation expression arguments", expression.getMark());
                }
                test = true;
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
