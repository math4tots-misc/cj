package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Tuple3;
import crossj.base.Tuple4;

public final class CJParser {
    private static final int ASSIGNMENT_PRECEDENCE = getTokenPrecedence('=');

    public static CJAstItemDefinition parseString(String path, String string) {
        var tokens = CJLexer.lex(string).get();
        var parser = new CJParser(path, tokens);
        return parser.parseTranslationUnit();
    }

    private final String path;
    private final List<CJToken> tokens;
    private int i = 0;

    private CJParser(String path, List<CJToken> tokens) {
        this.path = path;
        this.tokens = tokens;
    }

    private CJMark getMark() {
        return CJMark.fromToken(path, peek());
    }

    private CJToken peek() {
        return tokens.get(i);
    }

    private CJToken next() {
        return tokens.get(i++);
    }

    private boolean at(int type) {
        return peek().type == type;
    }

    private boolean atOffset(int type, int offset) {
        var j = i + offset;
        return j < tokens.size() && tokens.get(j).type == type;
    }

    private CJToken expect(int type) {
        if (!at(type)) {
            throw etype(type);
        }
        return next();
    }

    private boolean consume(int type) {
        if (at(type)) {
            next();
            return true;
        }
        return false;
    }

    private CJError etype(int type) {
        return ekind(CJToken.typeToString(type));
    }

    private CJError ekind(String kind) {
        return CJError.of("Expected " + kind + " but got " + CJToken.typeToString(peek().type), getMark());
    }

    private void expectDelimiters() {
        if (!at(';') && !at('}') && !at('\n')) {
            throw ekind("delimiter");
        }
        skipDelimiters();
    }

    private void skipDelimiters() {
        while (at(';') || at('\n')) {
            next();
        }
    }

    private String parseId() {
        return expect(CJToken.ID).text;
    }

    private String parseTypeId() {
        return expect(CJToken.TYPE_ID).text;
    }

    private Optional<String> parseComment() {
        if (at(CJToken.COMMENT)) {
            var ret = Optional.of(expect(CJToken.COMMENT).text);
            expectDelimiters();
            return ret;
        } else {
            return Optional.empty();
        }
    }

    private List<CJIRModifier> parseModifiers() {
        var modifiers = List.<CJIRModifier>of();
        var repeat = true;
        while (repeat) {
            switch (peek().type) {
                case CJToken.KW_NATIVE: {
                    next();
                    modifiers.add(CJIRModifier.Native);
                    break;
                }
                case CJToken.KW_STATIC: {
                    next();
                    modifiers.add(CJIRModifier.Static);
                    break;
                }
                case CJToken.KW_PUBLIC: {
                    next();
                    modifiers.add(CJIRModifier.Public);
                    break;
                }
                case CJToken.KW_PRIVATE: {
                    next();
                    modifiers.add(CJIRModifier.Private);
                    break;
                }
                default: {
                    repeat = false;
                }
            }
        }
        return modifiers;
    }

    private CJIRItemKind parseItemKind() {
        switch (peek().type) {
            case CJToken.KW_CLASS:
                next();
                return CJIRItemKind.Class;
            case CJToken.KW_UNION:
                next();
                return CJIRItemKind.Union;
            case CJToken.KW_TRAIT:
                next();
                return CJIRItemKind.Trait;
        }
        throw ekind("class, union or trait");
    }

    private String parsePackageName() {
        var sb = new StringBuilder();
        sb.append(parseId());
        while (at('.') && atOffset(CJToken.ID, 1)) {
            expect('.');
            sb.append('.');
            sb.append(parseId());
        }
        return sb.toString();
    }

    private String parseFullItemName() {
        var packageName = parsePackageName();
        expect('.');
        return packageName + "." + parseTypeId();
    }

    private CJAstItemDefinition parseTranslationUnit() {
        expect(CJToken.KW_PACKAGE);
        var packageName = parsePackageName();
        expectDelimiters();
        var imports = List.<CJAstImport>of();
        while (at(CJToken.KW_IMPORT)) {
            imports.add(parseImport());
        }
        var comment = parseComment();
        var modifiers = parseModifiers();
        var kind = parseItemKind();
        var mark = getMark();
        var shortName = parseTypeId();
        var typeParameters = parseTypeParameters(true);
        var traitDeclarations = parseTraitDeclarations();
        skipDelimiters();
        expect('{');
        skipDelimiters();
        var members = List.<CJAstItemMemberDefinition>of();
        while (!consume('}')) {
            members.add(parseItemMember());
        }
        skipDelimiters();
        if (!at(CJToken.EOF)) {
            throw ekind("EOF");
        }
        return new CJAstItemDefinition(mark, packageName, imports, comment, modifiers, kind, shortName, typeParameters,
                traitDeclarations, members);
    }

    private List<CJAstTypeParameter> parseTypeParameters(boolean itemLevel) {
        var parameters = List.<CJAstTypeParameter>of();
        if (consume('[')) {
            while (!consume(']')) {
                parameters.add(parseTypeParameter(itemLevel));
                if (!consume(',')) {
                    expect(']');
                    break;
                }
            }
        }
        return parameters;
    }

    private CJAstTypeParameter parseTypeParameter(boolean itemLevel) {
        var mark = getMark();
        var name = parseTypeId();
        var traits = List.<CJAstTraitExpression>of();
        if (consume(':')) {
            traits.add(parseTraitExpression());
        }
        return new CJAstTypeParameter(mark, itemLevel, name, traits);
    }

    private CJAstTraitExpression parseTraitExpression() {
        var mark = getMark();
        var name = parseTypeId();
        var args = parseTypeArgs();
        return new CJAstTraitExpression(mark, name, args);
    }

    private CJAstTypeExpression parseTypeExpression() {
        var mark = getMark();
        var name = parseTypeId();
        var args = parseTypeArgs();
        return new CJAstTypeExpression(mark, name, args);
    }

    private List<CJAstTypeExpression> parseTypeArgs() {
        var args = List.<CJAstTypeExpression>of();
        if (consume('[')) {
            while (!consume(']')) {
                args.add(parseTypeExpression());
                if (!consume(',')) {
                    expect(']');
                    break;
                }
            }
        }
        return args;
    }

    private CJAstImport parseImport() {
        expect(CJToken.KW_IMPORT);
        var mark = getMark();
        var fullName = parseFullItemName();
        expectDelimiters();
        return new CJAstImport(mark, fullName);
    }

    private List<CJAstTraitDeclaration> parseTraitDeclarations() {
        var declarations = List.<CJAstTraitDeclaration>of();
        skipDelimiters();
        if (consume(':')) {
            skipDelimiters();
            declarations.add(parseTraitDeclaration());
            skipDelimiters();
            while (consume(',')) {
                declarations.add(parseTraitDeclaration());
                skipDelimiters();
            }
        }
        return declarations;
    }

    private CJAstTraitDeclaration parseTraitDeclaration() {
        var mark = getMark();
        var trait = parseTraitExpression();
        var conditions = List.<CJAstTypeCondition>of();
        if (consume(CJToken.KW_IF)) {
            conditions.add(parseTypeCondition());
            while (consume(CJToken.KW_AND)) {
                conditions.add(parseTypeCondition());
            }
        }
        return new CJAstTraitDeclaration(mark, trait, conditions);
    }

    private CJAstTypeCondition parseTypeCondition() {
        var mark = getMark();
        var variableName = parseTypeId();
        var traits = List.<CJAstTraitExpression>of();
        expect(':');
        traits.add(parseTraitExpression());
        while (consume('&')) {
            traits.add(parseTraitExpression());
        }
        return new CJAstTypeCondition(mark, variableName, traits);
    }

    private CJAstItemMemberDefinition parseItemMember() {
        var modifiers = parseModifiers();
        switch (peek().type) {
            case CJToken.KW_VAL:
            case CJToken.KW_VAR:
                return parseFieldDefinition(modifiers);
            case CJToken.KW_CASE:
                return parseCaseDefinition(modifiers);
            case CJToken.KW_IF:
            case CJToken.KW_DEF:
                return parseMethod(modifiers);
        }
        throw ekind("val, var, def or if");
    }

    private CJAstFieldDefinition parseFieldDefinition(List<CJIRModifier> modifiers) {
        var mutable = next().type == CJToken.KW_VAR;
        var mark = getMark();
        var name = parseId();
        expect(':');
        var type = parseTypeExpression();
        var expression = consume('=') ? Optional.of(parseExpression()) : Optional.<CJAstExpression>empty();
        expectDelimiters();
        return new CJAstFieldDefinition(mark, modifiers, mutable, name, type, expression);
    }

    private CJAstCaseDefinition parseCaseDefinition(List<CJIRModifier> modifiers) {
        expect(CJToken.KW_CASE);
        var mark = getMark();
        var name = parseId();
        var types = List.<CJAstTypeExpression>of();
        if (consume('(')) {
            while (!consume(')')) {
                types.add(parseTypeExpression());
                if (!consume(',')) {
                    expect(')');
                    break;
                }
            }
        }
        expectDelimiters();
        return new CJAstCaseDefinition(mark, modifiers, name, types);
    }

    private CJAstMethodDefinition parseMethod(List<CJIRModifier> modifiers) {
        var conditions = List.<CJAstTypeCondition>of();
        if (consume(CJToken.KW_IF)) {
            conditions.add(parseTypeCondition());
            while (consume(CJToken.KW_AND)) {
                conditions.add(parseTypeCondition());
            }
        }
        skipDelimiters();
        modifiers.addAll(parseModifiers());
        expect(CJToken.KW_DEF);
        var mark = getMark();
        var name = parseId();
        var typeParameters = parseTypeParameters(false);
        var parameters = parseParameters();
        var returnType = consume(':') ? Optional.of(parseTypeExpression()) : Optional.<CJAstTypeExpression>empty();
        var body = consume('=') ? Optional.of(parseExpression()) : Optional.<CJAstExpression>empty();
        expectDelimiters();
        return new CJAstMethodDefinition(mark, conditions, modifiers, name, typeParameters, parameters, returnType,
                body);
    }

    private List<CJAstParameter> parseParameters() {
        expect('(');
        var list = List.<CJAstParameter>of();
        while (!consume(')')) {
            list.add(parseParameter());
            if (!consume(',')) {
                expect(')');
                break;
            }
        }
        return list;
    }

    private CJAstParameter parseParameter() {
        var mutable = consume(CJToken.KW_VAR);
        var mark = getMark();
        var name = parseId();
        expect(':');
        var type = parseTypeExpression();
        return new CJAstParameter(mark, mutable, name, type);
    }

    private CJAstExpression parseExpression() {
        return parseExpressionWithPrecedence(0);
    }

    private CJAstExpression parseExpressionWithPrecedence(int precedence) {
        var expr = parseAtomExpression();
        var tokenPrecedence = getTokenPrecedence(peek().type);
        while (tokenPrecedence >= precedence) {
            var opMark = getMark();
            switch (peek().type) {
                case '.': {
                    next();
                    var methodMark = getMark();
                    var name = parseId();
                    var args = List.of(expr);
                    if (at('(') || at('[')) {
                        var typeArgs = parseTypeArgs();
                        args.addAll(parseArgs());
                        expr = new CJAstMethodCall(methodMark, Optional.empty(), name, typeArgs, args);
                    } else if (consume('=')) {
                        var methodName = "__set_" + name;
                        args.add(parseExpression());
                        expr = new CJAstMethodCall(methodMark, Optional.empty(), methodName, List.of(), args);
                    } else {
                        var methodName = "__get_" + name;
                        expr = new CJAstMethodCall(methodMark, Optional.empty(), methodName, List.of(), args);
                    }
                    break;
                }
                case '=': {
                    next();
                    var valexpr = parseExpression();
                    var target = expressionToTarget(expr);
                    expr = new CJAstAssignment(opMark, target, valexpr);
                    break;
                }
                case '+':
                case '-':
                case '*':
                case '/':
                case '%':
                case '<':
                case '>':
                case '|':
                case '^':
                case '&':
                case CJToken.LSHIFT:
                case CJToken.RSHIFT:
                case CJToken.RSHIFTU:
                case CJToken.POWER:
                case CJToken.TRUNCDIV:
                case CJToken.EQ:
                case CJToken.NE:
                case CJToken.LE:
                case CJToken.GE:
                case CJToken.KW_IN:
                case CJToken.KW_NOT: {
                    String methodName = null;
                    boolean logicalNot = false;
                    boolean rightAssociative = false;
                    boolean swap = false;
                    var mark = getMark();
                    switch (next().type) {
                        case '+':
                            methodName = "__add";
                            break;
                        case '-':
                            methodName = "__sub";
                            break;
                        case '*':
                            methodName = "__mul";
                            break;
                        case '/':
                            methodName = "__div";
                            break;
                        case '%':
                            methodName = "__rem";
                            break;
                        case '<':
                            methodName = "__lt";
                            break;
                        case '>':
                            methodName = "__gt";
                            break;
                        case '|':
                            methodName = "__or";
                            break;
                        case '^':
                            methodName = "__xor";
                            break;
                        case '&':
                            methodName = "__and";
                            break;
                        case CJToken.LSHIFT:
                            methodName = "__lshift";
                            break;
                        case CJToken.RSHIFT:
                            methodName = "__rshift";
                            break;
                        case CJToken.RSHIFTU:
                            methodName = "__rshiftu";
                            break;
                        case CJToken.POWER:
                            methodName = "__pow";
                            rightAssociative = true;
                            break;
                        case CJToken.TRUNCDIV:
                            methodName = "__truncdiv";
                            break;
                        case CJToken.EQ:
                            methodName = "__eq";
                            break;
                        case CJToken.NE:
                            methodName = "__eq";
                            logicalNot = true;
                            break;
                        case CJToken.LE:
                            methodName = "__le";
                            break;
                        case CJToken.GE:
                            methodName = "__ge";
                            break;
                        case CJToken.KW_IN:
                            methodName = "__contains";
                            swap = true;
                            break;
                        case CJToken.KW_NOT:
                            expect(CJToken.KW_IN);
                            methodName = "__contains";
                            logicalNot = true;
                            swap = true;
                            break;
                    }
                    Assert.that(methodName != null);
                    var rhs = parseExpressionWithPrecedence(rightAssociative ? tokenPrecedence : tokenPrecedence + 1);
                    if (swap) {
                        var tmp = rhs;
                        rhs = expr;
                        expr = tmp;
                    }
                    expr = new CJAstMethodCall(mark, Optional.empty(), methodName, List.of(), List.of(expr, rhs));
                    if (logicalNot) {
                        expr = new CJAstLogicalNot(mark, expr);
                    }
                    break;
                }
                default:
                    throw ekind("expression operator (TODO)");
            }
            tokenPrecedence = getTokenPrecedence(peek().type);
        }
        return expr;
    }

    private static int getTokenPrecedence(int tokenType) {
        // mostly follows Python, except uses Rust style '?'
        switch (tokenType) {
            case '=':
                return 20;
            case CJToken.KW_OR:
                return 40;
            case CJToken.KW_AND:
                return 50;
            case '<':
            case '>':
            case CJToken.EQ:
            case CJToken.NE:
            case CJToken.GE:
            case CJToken.LE:
            case CJToken.KW_IS:
            case CJToken.KW_IN:
            case CJToken.KW_NOT:
                return 60;
            case '|':
                return 70;
            case '^':
                return 80;
            case '&':
                return 90;
            case CJToken.LSHIFT:
            case CJToken.RSHIFT:
            case CJToken.RSHIFTU:
                return 100;
            case '+':
            case '-':
                return 110;
            case '*':
            case '/':
            case '%':
            case CJToken.TRUNCDIV:
                return 120;
            case CJToken.POWER:
                return 130;
            case '.':
            case '?':
                return 140;
            default:
                return -1;
        }
    }

    private CJAstExpression parseAtomExpression() {
        switch (peek().type) {
            case '{':
                return parseBlock();
            case '(': {
                var mark = getMark();
                if (atOffset(')', 1)) {
                    next();
                    next();
                    return new CJAstLiteral(mark, CJIRLiteralKind.Unit, "()");
                } else {
                    next();
                    var inner = parseExpression();
                    expect(')');
                    return inner;
                }
            }
            case CJToken.KW_TRUE:
                return new CJAstLiteral(getMark(), CJIRLiteralKind.Bool, "true");
            case CJToken.KW_FALSE:
                return new CJAstLiteral(getMark(), CJIRLiteralKind.Bool, "false");
            case CJToken.INT:
                return new CJAstLiteral(getMark(), CJIRLiteralKind.Int, next().text);
            case CJToken.DOUBLE:
                return new CJAstLiteral(getMark(), CJIRLiteralKind.Double, next().text);
            case CJToken.STRING:
                return new CJAstLiteral(getMark(), CJIRLiteralKind.String, next().text);
            case CJToken.TYPE_ID: {
                var owner = parseTypeExpression();
                expect('.');
                var mark = getMark();
                var name = parseId();
                if (at('[') || at('(')) {
                    var typeArgs = parseTypeArgs();
                    var args = parseArgs();
                    return new CJAstMethodCall(mark, Optional.of(owner), name, typeArgs, args);
                } else if (consume('=')) {
                    var methodName = "__set_" + name;
                    var args = List.of(parseExpression());
                    return new CJAstMethodCall(mark, Optional.of(owner), methodName, List.of(), args);
                } else {
                    var methodName = "__get_" + name;
                    return new CJAstMethodCall(mark, Optional.of(owner), methodName, List.of(), List.of());
                }
            }
            case CJToken.ID:
                return new CJAstVariableAccess(getMark(), parseId());
            case CJToken.KW_VAL:
            case CJToken.KW_VAR: {
                var mutable = next().type == CJToken.KW_VAR;
                var mark = getMark();
                var target = expressionToTarget(parseExpressionWithPrecedence(ASSIGNMENT_PRECEDENCE + 5));
                var declaredType = consume(':') ? Optional.of(parseTypeExpression())
                        : Optional.<CJAstTypeExpression>empty();
                expect('=');
                var expression = parseExpression();
                return new CJAstVariableDeclaration(mark, mutable, target, declaredType, expression);
            }
            case CJToken.KW_UNION: {
                var mark = getMark();
                next();
                var target = parseExpression();
                expect('{');
                skipDelimiters();
                var cases = List.<Tuple4<CJMark, String, List<Tuple3<CJMark, Boolean, String>>, CJAstExpression>>of();
                while (!at('}') && !at(CJToken.KW_DEFAULT)) {
                    var caseMark = getMark();
                    expect(CJToken.KW_CASE);
                    var caseName = parseId();
                    var decls = List.<Tuple3<CJMark, Boolean, String>>of();
                    if (consume('(')) {
                        while (!consume(')')) {
                            var mutable = consume(CJToken.KW_VAR);
                            var varMark = getMark();
                            var varName = parseId();
                            decls.add(Tuple3.of(varMark, mutable, varName));
                            if (!consume(',')) {
                                expect(')');
                                break;
                            }
                        }
                    }
                    expect('=');
                    var body = parseExpression();
                    cases.add(Tuple4.of(caseMark, caseName, decls, body));
                    expectDelimiters();
                }
                Optional<CJAstExpression> fallback;
                if (consume(CJToken.KW_DEFAULT)) {
                    expect('=');
                    fallback = Optional.of(parseExpression());
                } else {
                    fallback = Optional.empty();
                }
                expect('}');
                return new CJAstUnion(mark, target, cases, fallback);
            }
        }
        throw ekind("expression");
    }

    // private boolean atLambda() {
    //     if (at(CJToken.ID) && atOffset(CJToken.RIGHT_ARROW, 1)) {
    //         return true;
    //     }
    // }

    private List<CJAstExpression> parseArgs() {
        var list = List.<CJAstExpression>of();
        expect('(');
        while (!consume(')')) {
            list.add(parseExpression());
            if (!consume(',')) {
                expect(')');
                break;
            }
        }
        return list;
    }

    private CJAstBlock parseBlock() {
        var mark = getMark();
        expect('{');
        skipDelimiters();
        var exprs = List.<CJAstExpression>of();
        while (!consume('}')) {
            exprs.add(parseExpression());
            expectDelimiters();
        }
        return new CJAstBlock(mark, exprs);
    }

    private CJAstAssignmentTarget expressionToTarget(CJAstExpression expression) {
        if (expression instanceof CJAstVariableAccess) {
            var e = (CJAstVariableAccess) expression;
            return new CJAstNameAssignmentTarget(e.getMark(), e.getName());
        } else {
            throw CJError.of("Expected assignment target but got " + expression.getClass().getName(),
                    expression.getMark());
        }
    }
}
