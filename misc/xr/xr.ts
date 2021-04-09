
class Source {
    readonly path: string
    readonly contents: string
    constructor(path: string, contents: string) {
        this.path = path;
        this.contents = contents;
    }
    toString() {
        return this.path;
    }
}

class Mark {
    static readonly builtin = new Mark(new Source('<builtin>', ''), 0, 1, 1);
    readonly source: Source
    readonly i: number
    readonly line: number
    readonly column: number
    constructor(source: Source, i: number, line: number, column: number) {
        this.source = source;
        this.i = i;
        this.line = line;
        this.column = column;
    }
    toString() {
        return this.source.path + ":" + this.line + ":" + this.column;
    }
}

class MError extends Error {
    readonly msg: string
    readonly marks: Mark[]
    constructor(msg: string, marks: Mark[]) {
        super(msg + "\n" + marks.map(m => "  " + m).join("\n"));
        this.msg = msg;
        this.marks = Array.from(marks);
    }
}

// token types
const TTEOF = 'EOF';
const TTID = 'ID';
const TTMACROID = 'MACROID';
const TTINT = 'INT';
const TTDOUBLE = 'DOUBLE';
const TTSTR = 'STR';
const TTNEWLINE = 'NEWLINE';
class Token {
    mark: Mark
    type: string
    value: null | string | number
    constructor(mark: Mark, type: string, value: null | string | number) {
        this.mark = mark;
        this.type = type;
        this.value = value;
    }
    toString() {
        return "Token(" + this.type + "," + this.value + ")";
    }
}

const KEYWORDS = new Set([
    'class', 'interface', 'def',
    'let',
    'const',
    'val',
    'var',
    'and', 'or', 'not',
]);
const SYMBOLS = [
    '...',
    '.',
    '++',
    '=',
    '+',
].sort().reverse();

function unrepr(s: string): string {
    // TODO: Avoid the use of eval
    return s.substring(1, s.length - 1)
        .replace(/\\((x|u)[0-9a-zA-Z]+|.)/g, match => eval('"' + match + '"'));
}

function lex(path: string, contents: string): Token[] {
    const source = new Source(path, contents);
    const s = contents;
    let i = 0, line = 1, column = 1, lastI = i, lastLine = line, lastColumn = column;
    const toks: Token[] = [];
    const parenStack: string[] = [];

    function incr() {
        if (i < s.length) {
            if (s[i] === '\n') {
                line++;
                column = 1;
            } else {
                column++;
            }
            i++;
        }
    }

    function newMark() {
        return new Mark(source, lastI, lastLine, lastColumn);
    }

    function addTok(type: string, value: null | string | number = null) {
        toks.push(new Token(newMark(), type, value));
    }

    function skipSpaces() {
        const skipSet = (
            (parenStack.length === 0 || parenStack[parenStack.length - 1] === '{') ?
                ' \t\r' : ' \t\r\n');
        while (i < s.length && skipSet.includes(s[i])) {
            incr();
        }
    }

    tokenLoop:
    while (true) {
        skipSpaces();
        lastI = i;
        lastLine = line;
        lastColumn = column;
        if (i >= s.length) break;
        const start = i;
        let ch = s[i];
        incr();
        if (ch === '#') {
            while (i < s.length && s[i] !== '\n') {
                incr();
            }
            continue;
        }
        if (ch === '\n') {
            addTok(TTNEWLINE);
            continue;
        }
        if ('([{'.includes(ch)) {
            addTok(ch);
            parenStack.push(ch);
            continue;
        }
        if (')]}'.includes(ch)) {
            addTok(ch);
            parenStack.pop();
            continue;
        }
        if (ch === '"' || ch == "'") {
            while (i < s.length && s[i] !== ch) {
                if (s[i] === '\\') {
                    incr();
                }
                incr();
            }
            incr();
            const value: string = unrepr(s.substring(start, i));
            addTok(TTSTR, value);
            continue;
        }
        if (ch.match(/[a-zA-Z_]/)) {
            while (i < s.length && s[i].match(/[a-zA-Z0-9_]/)) {
                incr();
            }
            const name = s.substring(start, i);
            if (i < s.length && s[i] === '!') {
                incr();
                addTok(TTMACROID, name);
            } else {
                if (KEYWORDS.has(name)) {
                    addTok(name);
                } else {
                    addTok(TTID, name);
                }
            }
            continue;
        }
        if (ch.match(/[0-9]/)) {
            while (i < s.length && s[i].match(/[0-9]/)) incr();
            if (s[i] === '.') {
                incr();
                while (i < s.length && s[i].match(/[0-9]/)) incr();
                const value = parseFloat(s.substring(start, i));
                addTok(TTDOUBLE, value);
            } else {
                const value = parseInt(s.substring(start, i));
                addTok(TTINT, value);
            }
            continue;
        }
        for (const sym of SYMBOLS) {
            if (s.startsWith(sym, start)) {
                while (i < start + sym.length) incr();
                addTok(sym);
                continue tokenLoop;
            }
        }
        throw new MError("Unrecognized token " + JSON.stringify(ch), [newMark()]);
    }
    addTok(TTEOF);
    return toks;
}

class Context {
    readonly stack: Mark[] = []
    constructor() {
    }
    error(message: string) {
        return new MError(message, this.stack);
    }
}

abstract class Ast {
    mark: Mark
    constructor(mark: Mark) { this.mark = mark }
}

abstract class ExprAst extends Ast {}

class TypeExprAst extends ExprAst {
    name: string
    args: TypeExprAst[]
    constructor(mark: Mark, name: string, args: TypeExprAst[]) {
        super(mark);
        this.name = name;
        this.args = args;
    }
}

class ProgramAst extends Ast {
    items: ItemAst[]
    constructor(mark: Mark, items: ItemAst[]) {
        super(mark);
        this.items = items;
    }
}

abstract class ItemAst extends Ast {
    name: string
    constructor(mark: Mark, name: string) {
        super(mark);
        this.name = name;
    }
}

class VarAst extends Ast {
    name: string
    type: TypeExprAst
    constructor(mark: Mark, name: string, type: TypeExprAst) {
        super(mark);
        this.name = name;
        this.type = type;
    }
}

class FuncAst extends ItemAst {
    params: VarAst[]
    returnType: TypeExprAst
    body: ExprAst
    constructor(mark: Mark, name: string, params: VarAst[], returnType: TypeExprAst, body: ExprAst) {
        super(mark, name);
        this.params = params;
        this.returnType = returnType;
        this.body = body;
    }
}

class CallAst extends ExprAst {
    functionName: string
    args: ExprAst[]
}

function precof(type: string): number {
    switch (type) {
        case '.':case '(':case '[':case '=>':case'++':case'--': return 150
        case '*':case '/':case '%': return 130
        case '+':case '-': return 120
        case '<<':case '>>': return 110
        case '<':case '>':case '<=':case '>=': return 100
        case '==':case '!=': return 90
        case '&': return 80
        case '^': return 70
        case '|': return 60
        case '&&':case 'and': return 50
        case '||':case 'or': return 40
        case '?': return 30
        case '=': case '+=': case '-=': case '*=':
        case '/=': case '%=': case '&=': case '|=': case '^=':
        case '<<=': case '>>=': return 20;
        default: return -10;
    }
}

function parse(ctx: Context, path: string, contents: string): Scope {
    const startScope = ctx.scope;
    ctx.scope = ctx.rootScope.spawn(path);
    const tokens = lex(path, contents);
    let i = 0;

    function mark() {
        return peek().mark;
    }

    function peek() {
        return tokens[i];
    }

    function at(type: string, offset: number = 0): boolean {
        let j = i + offset;
        return j < tokens.length && tokens[j].type === type;
    }

    function next() {
        return tokens[i++];
    }

    function consume(type: string) {
        if(at(type)) {
            next();
            return true;
        }
        return false;
    }

    function assert(type: string) {
        if (!at(type)) {
            ctx.stack.push(mark());
            throw ctx.error("Expected " + type + " but got " + peek().type);
        }
    }

    function expect(type: string) {
        assert(type);
        return next();
    }

    function skipDelim() {
        while (consume(TTNEWLINE) || consume(';')) {}
    }

    function expectDelim() {
        if (!(at(TTEOF) || at('}') || at(TTNEWLINE) || at(';'))) {
            ctx.stack.push(mark());
            throw ctx.error("Expected delimiter");
        }
        skipDelim();
    }

    function newBlock(mark: Mark, exprs: Expr[]): Expr {
        if (exprs.length === 0) {
            return new Nop(mark, TVOID);
        } else {
            return new Block(mark, exprs[exprs.length - 1].type, exprs);
        }
    }

    function parseStmt(): Expr {
        const expr = parseExpr();
        expectDelim();
        return expr;
    }

    function parseBlock(): Expr {
        const m = mark();
        expect('{');
        skipDelim();
        const stmts: Expr[] = [];
        while (!consume('}')) {
            stmts.push(parseStmt());
        }
        return newBlock(m, stmts);
    }

    function parseExpr(): Expr {
        return parseExprPr(0);
    }

    function mcall(mark: Mark, owner: Expr, methodName: string, args: Expr[]): Expr {
        switch (methodName) {
            case 'and': return new LogicalAnd(mark, owner, args[0]);
            case 'or': return new LogicalOr(mark, owner, args[0]);
        }
        return new Call(mark, owner, methodName, args);
    }

    function fcall(mark: Mark, owner: Expr, args: Expr[]): Expr {
        return new Call(mark, owner, null, args);
    }

    function parseJoin<T>(open: string, close: string, sep: string, single: () => T): T[] {
        expect(open);
        const ret: T[] = [];
        while (!consume(close)) {
            ret.push(single());
            if (!consume(sep)) {
                assert(close);
            }
        }
        return ret;
    }

    function parseArgs() {
        return parseJoin('(', ')', ',', parseExpr);
    }

    function parseParam() {
        const m = mark();
        const variadic = consume('...');
        const mutable = consume('var');
        const name = expect(TTID).value as string;
        return new Param(m, variadic, mutable, name);
    }

    function parseParams() {
        return parseJoin('(', ')', ',', parseParam);
    }

    function parseExprPr(precedence: number): Expr {
        let expr = parseAtom();
        let tokprec = precof(peek().type);
        while (precedence < tokprec) {
            const m = mark();
            switch (peek().type) {
                case '.': {
                    next();
                    const name = expect(TTID).value as string;
                    const args = parseArgs();
                    expr = mcall(m, expr, name, args);
                    break;
                }
                case '(': {
                    const args = parseArgs();
                    expr = fcall(m, expr, args);
                    break;
                }
                case '+': case '-': case '*': case '/': case 'and': case 'or': {
                    // all left associative binops
                    const op = next().type;
                    let methodName = '';
                    switch (op) {
                        case '+': methodName = '__add'; break;
                        case '-': methodName = '__sub'; break;
                        case '*': methodName = '__mul'; break;
                        case '/': methodName = '__div'; break;
                        case 'and': methodName = 'and'; break;
                        case 'or': methodName = 'or'; break;
                        default: {
                            ctx.stack.push(m);
                            throw ctx.error("TODO binop " + op);
                        }
                    }
                    expr = mcall(m, expr, methodName, [parseExprPr(tokprec)]);
                    break;
                }
                default: {
                    ctx.stack.push(m);
                    throw ctx.error("TODO operator " + peek().type);
                }
            }
            tokprec = precof(peek().type);
        }
        return expr;
    }

    function parseAtom(): Expr {
        const m = mark();
        switch (peek().type) {
            case TTID: {
                const name = next().value as string;
                return new GetVar(m, name);
            }
            case TTINT: case TTDOUBLE: case TTSTR: {
                const value = next().value;
                return new Literal(m, value);
            }
            case 'null': next(); return new Literal(m, null);
            case 'true': next(); return new Literal(m, true);
            case 'false': next(); return new Literal(m, false);
            case 'val': case 'var': {
                const mutable = next().type === 'var';
                const name = expect(TTID).value as string;
                const initexpr = consume('=') ? parseExpr() : new Literal(m, null);
                return new DeclVar(m, mutable, name, initexpr);
            }
            case 'def': {
                next();
                const name = at(TTID) ? next().value as string : null;
                const params = parseParams();
                const body = consume('=') ? parseExpr() : parseBlock();
                const funcdef = new FuncDef(m, name, params, body);
                if (name == null) {
                    return funcdef;
                } else {
                    return new DeclVar(m, false, name, funcdef);
                }
            }
            case '(': {
                next();
                const expr = parseExpr();
                expect(')');
                return expr;
            }
            default: {
                ctx.stack.push(m);
                throw ctx.error("Expected expression");
            }
        }
    }

    const startMark = mark();
    const stmts: Expr[] = [];
    skipDelim();
    while (!at(TTEOF)) {
        stmts.push(parseStmt());
    }

    ctx.scope = startScope;
    return new Module(startMark, stmts);
}

{
    const ctx = new Context();
    const module = ctx.parse('<test>', `
    val x = 10
    val y = x.__add(14)
    print("x = " + x)
    print("y = " + y)
    print("hello world")

    def twice(s) {
        print(s)
        print(s)
    }

    twice("some text")
    twice('some text2')
    twice('asdf \\x26 asdf')
    twice('asdf \\u2677 asdf')
    `);
    module.eval(ctx);
}
