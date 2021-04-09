
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
    'def',
    'let',
    'const',
    'val',
    'var',
    'and', 'or', 'not',
]);
const SYMBOLS = [
    '...',
    ',',
    '.',
    '++',
    '=',
    '+',
].sort().reverse();
const SYMBOLS_BY_FIRST_CHAR: Map<string, string[]> = new Map();
for (const symbol of SYMBOLS) {
    if (!SYMBOLS_BY_FIRST_CHAR.has(symbol[0])) {
        SYMBOLS_BY_FIRST_CHAR.set(symbol[0], []);
    }
    SYMBOLS_BY_FIRST_CHAR.get(symbol[0])!.push(symbol);
}

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
        const symbols = SYMBOLS_BY_FIRST_CHAR.get(ch);
        if (symbols !== undefined) {
            for (const sym of symbols) {
                if (s.startsWith(sym, start)) {
                    while (i < start + sym.length) incr();
                    addTok(sym);
                    continue tokenLoop;
                }
            }
        }
        throw new MError("Unrecognized token " + JSON.stringify(ch), [newMark()]);
    }
    addTok(TTEOF);
    return toks;
}

class Context {
    readonly stack: Mark[] = []
    scope: Scope
    constructor(scope: Scope | null = null) {
        this.scope = scope || ROOT;
    }
    error(message: string) {
        return new MError(message, this.stack);
    }
    checkMinArgc(args: Value[], argc: number, mark: Mark | null = null) {
        if (mark) {
            this.stack.push(mark);
        }
        if (args.length < argc) {
            throw this.error("Expected at least " + argc + " args but got " + args.length);
        }
    }
    checkArgc(args: Value[], argc: number, mark: Mark | null = null) {
        if (mark) {
            this.stack.push(mark);
        }
        if (args.length !== argc) {
            throw this.error("Expected " + argc + " args but got " + args.length);
        }
    }
    parse(path: string, contents: string): Module {
        return parse(this, path, contents);
    }
}

class Entry {
    readonly mutable: boolean
    value: Value
    constructor(mutable: boolean, value: Value) {
        this.mutable = mutable;
        this.value = value;
    }
}

type Scope = { [key: string] : Entry }

type ValueArray = { readonly length : number, [key: number] : Value };
type ValueObject = Scope;
type ValueFn = (ctx: Context, self: Value, args: Value[]) => Value;
type Value = null | boolean | number | string | ValueArray | ValueObject | ValueFn;

function newScope(parent: Scope | null): Scope {
    return Object.create(parent);
}
const ROOT: Scope = newScope(null);
ROOT['print'] = new Entry(false, (ctx, self, args) => {
    ctx.checkArgc(args, 1);
    console.log(convStr(ctx, args[0]));
    return null;
});
ROOT['str'] = new Entry(false, (ctx, self, args) => {
    ctx.checkArgc(args, 1);
    return convStr(ctx, args[0]);
});

function typestr(value: Value): string {
    switch (typeof value) {
        case "object":
            if (value === null) {
                return "null";
            } else if (Array.isArray(value)) {
                return "array";
            }
            return "object";
        default: return typeof value;
    }
}

abstract class Expr {
    readonly mark: Mark
    constructor(mark: Mark) {
        this.mark = mark;
    }
    abstract eval(ctx: Context): Value
}

class Module extends Expr {
    readonly exprs: Expr[]
    constructor(mark: Mark, exprs: Expr[]) {
        super(mark);
        this.exprs = exprs;
    }
    eval(ctx: Context) {
        const oldScope = ctx.scope;
        const scope: Scope = newScope(oldScope);
        ctx.scope = scope;
        for (const expr of this.exprs) {
            expr.eval(ctx);
        }
        ctx.scope = oldScope;
        return scope;
    }
}

class Block extends Expr {
    readonly exprs: Expr[]
    constructor(mark: Mark, exprs: Expr[]) {
        super(mark);
        this.exprs = exprs;
    }
    eval(ctx: Context) {
        const oldScope = ctx.scope;
        ctx.scope = newScope(oldScope);
        let last: Value = null;
        for (const expr of this.exprs) {
            last = expr.eval(ctx);
        }
        ctx.scope = oldScope;
        return last;
    }
}

class Literal extends Expr {
    readonly value: Value
    constructor(mark: Mark, value: Value) {
        super(mark);
        this.value = value;
    }
    eval(ctx: Context) { return this.value }
}

class ListDisplay extends Expr {
    readonly exprs: Expr[]
    constructor(mark: Mark, exprs: Expr[]) {
        super(mark);
        this.exprs = exprs;
    }
    eval(ctx: Context) { return this.exprs.map(e => e.eval(ctx)); }
}

class GetVar extends Expr {
    readonly name: string
    constructor(mark: Mark, name: string) {
        super(mark);
        this.name = name;
    }
    eval(ctx: Context) {
        const entry = ctx.scope[this.name];
        if (entry === undefined) {
            ctx.stack.push(this.mark);
            throw ctx.error("Variable '" + this.name + "' not found");
        }
        return entry.value;
    }
}

class SetVar extends Expr {
    readonly name: string
    readonly valexpr: Expr
    constructor(mark: Mark, name: string, valexpr: Expr) {
        super(mark);
        this.name = name;
        this.valexpr = valexpr;
    }
    eval(ctx: Context) {
        const entry = ctx.scope[this.name];
        if (entry === undefined) {
            ctx.stack.push(this.mark);
            throw ctx.error("Variable '" + this.name + "' not found");
        }
        return entry.value = this.valexpr.eval(ctx);
    }
}

class DeclVar extends Expr {
    readonly mutable: boolean
    readonly name: string
    readonly initexpr: Expr
    constructor(mark: Mark, mutable: boolean, name: string, initexpr: Expr) {
        super(mark);
        this.mutable = mutable;
        this.name = name;
        this.initexpr = initexpr;
    }
    eval(ctx: Context) {
        if (Object.prototype.hasOwnProperty.call(ctx.scope, this.name)) {
            ctx.stack.push(this.mark);
            throw ctx.error("Variable '" + this.name + "' is already declared in this scope");
        }
        const entry = new Entry(this.mutable, this.initexpr.eval(ctx));
        ctx.scope[this.name] = entry;
        return null;
    }
}

class Param {
    readonly mark: Mark
    readonly variadic: boolean
    readonly mutable: boolean
    readonly name: string
    constructor(mark: Mark, variadic: boolean, mutable: boolean, name: string) {
        this.mark = mark;
        this.variadic = variadic;
        this.mutable = mutable;
        this.name = name;
    }
}

class FuncDef extends Expr {
    readonly name: string | null
    readonly params: Param[]
    readonly body: Expr
    constructor(mark: Mark, name: string | null, params: Param[], body: Expr) {
        super(mark);
        this.name = name;
        this.params = params;
        this.body = body;
    }
    eval(octx: Context): ValueFn {
        const mark = this.mark;
        const body = this.body;
        const params = this.params;
        const fscope = octx.scope;
        return (ictx, self, args) => {
            const oldScope = ictx.scope;
            ictx.scope = newScope(fscope);
            let i = 0, j = 0;
            while (i < params.length && j < args.length) {
                const param = params[i++];
                if (param.variadic) {
                    const arg = args.slice(j);
                    j = args.length;
                    ictx.scope[param.name] = new Entry(param.mutable, arg);
                } else {
                    ictx.scope[param.name] = new Entry(param.mutable, args[j++]);
                }
            }
            if (i < params.length) {
                ictx.stack.push(params[i].mark);
                throw ictx.error("Expected more arguments");
            }
            if (j < args.length) {
                ictx.stack.push(mark);
                throw ictx.error("Too many arguments");
            }
            ictx.scope["this"] = new Entry(false, self);
            const ret = body.eval(ictx);
            ictx.scope = oldScope;
            return ret;
        }
    }
}

class GetField extends Expr {
    readonly owner: Expr
    readonly fieldName: string
    constructor(mark: Mark, owner: Expr, fieldName: string) {
        super(mark);
        this.owner = owner;
        this.fieldName = fieldName;
    }
    eval(ctx: Context) {
        const owner = this.owner.eval(ctx);
        const entry = (owner as ValueObject)[this.fieldName];
        if (entry === undefined) {
            ctx.stack.push(this.mark);
            throw ctx.error("Field '" + this.fieldName + "' not found");
        }
        return entry.value;
    }
}

function truthy(ctx: Context, value: Value): boolean {
    if (Array.isArray(value)) {
        return !!value.length;
    }
    if (value !== null && typeof value === 'object' && '__bool' in value) {
        return !!callm(ctx, value, '__bool', []);
    }
    return !!value;
}

class LogicalAnd extends Expr {
    readonly lhs: Expr
    readonly rhs: Expr
    constructor(mark: Mark, lhs: Expr, rhs: Expr) {
        super(mark);
        this.lhs = lhs;
        this.rhs = rhs;
    }
    eval(ctx: Context) {
        const lhs = this.lhs.eval(ctx);
        return truthy(ctx, lhs) ? this.rhs.eval(ctx) : lhs;
    }
}

class LogicalOr extends Expr {
    readonly lhs: Expr
    readonly rhs: Expr
    constructor(mark: Mark, lhs: Expr, rhs: Expr) {
        super(mark);
        this.lhs = lhs;
        this.rhs = rhs;
    }
    eval(ctx: Context) {
        const lhs = this.lhs.eval(ctx);
        return truthy(ctx, lhs) ? lhs : this.rhs.eval(ctx);
    }
}

class If extends Expr {
    readonly cond: Expr
    readonly lhs: Expr
    readonly rhs: Expr
    constructor(mark: Mark, cond: Expr, lhs: Expr, rhs: Expr) {
        super(mark);
        this.cond = cond;
        this.lhs = lhs;
        this.rhs = rhs;
    }
    eval(ctx: Context) {
        return truthy(ctx, this.cond.eval(ctx)) ? this.lhs.eval(ctx) : this.rhs.eval(ctx);
    }
}

class While extends Expr {
    readonly cond: Expr
    readonly body: Expr
    constructor(mark: Mark, cond: Expr, body: Expr) {
        super(mark);
        this.cond = cond;
        this.body = body;
    }
    eval(ctx: Context) {
        while (truthy(ctx, this.cond.eval(ctx))) {
            this.body.eval(ctx);
        }
        return null;
    }
}

class Call extends Expr {
    readonly owner: Expr
    readonly methodName: string | null
    readonly args: Expr[]
    constructor(mark: Mark, owner: Expr, methodName: string | null, args: Expr[]) {
        super(mark);
        this.owner = owner;
        this.methodName = methodName;
        this.args = args;
    }
    eval(ctx: Context) {
        const owner = this.owner.eval(ctx);
        const args = this.args.map(arg => arg.eval(ctx));
        const methodName = this.methodName;
        ctx.stack.push(this.mark);
        try {
            if (methodName === null) {
                if (typeof owner !== 'function') {
                    throw ctx.error("Expected function but got " + typestr(owner));
                }
                return owner(ctx, null, args);
            } else {
                return callm(ctx, owner, methodName, args);
            }
        } finally {
            ctx.stack.pop();
        }
    }
}

function castNum(ctx: Context, x: Value): number {
    if (typeof x === 'number') { return x }
    throw ctx.error("Expected number");
}

function castStr(ctx: Context, x: Value): string {
    if (typeof x === 'string') { return x }
    throw ctx.error("Expected string");
}

function convStr(ctx: Context, x: Value): string {
    switch (typeof x) {
        case 'string': return x;
        case 'object': {
            if (x !== null && typeof x === 'object' && '__str' in x) {
                return '' + callm(ctx, x, '__str', []);
            } else if (Array.isArray(x)) {
                return '[' + x.map(a => convStr(ctx, a)).join(', ') + ']';
            } else {
                return JSON.stringify(x);
            }
        }
    }
    return '' + x;
}

function callf(ctx: Context, f: Value, args: Value[]) {
    if (typeof f !== 'function') {
        throw ctx.error('Expected function but got ' + typestr(f));
    }
    return f(ctx, null, args);
}


function callm(ctx: Context, owner: Value, methodName: string, args: Value[]) {
    switch (typeof owner) {
        case 'number': {
            switch (methodName) {
                case '__add': return owner + castNum(ctx, args[0]);
                case '__sub': return owner - castNum(ctx, args[0]);
                case '__mul': return owner * castNum(ctx, args[0]);
                case 'str':case 'repr': return '' + owner;
            }
            throw ctx.error("Method '" + methodName + "' not found on number");
            break;
        }
        case 'string': {
            switch (methodName) {
                case '__add': return owner + convStr(ctx, args[0]);
                case 'str': return owner;
                case 'repr': return JSON.stringify(owner);
            }
            throw ctx.error("Method '" + methodName + "' not found on string");
            break;
        }
        case 'object': {
            if (Array.isArray(owner)) {
                switch (methodName) {
                    case 'push': {
                        owner.push(args[0]);
                        return null;
                    }
                    case 'pop': {
                        if (owner.length === 0) { throw ctx.error("Pop from empty list") }
                        return owner.pop();
                    }
                    case 'map': {
                        return owner.map(x => callf(ctx, args[0], x));
                    }
                }
                throw ctx.error("Method '" + methodName + "' not found on list");
            }
            break;
        }
    }
    const entry = (owner as ValueObject)[methodName];
    if (entry === undefined) {
        throw ctx.error("Method '" + methodName + "' not found");
    }
    const f = entry.value;
    if (typeof f !== 'function') {
        throw ctx.error("Field '" + methodName + "' is not a method (" + typestr(f) + ")");
    }
    return f(ctx, owner, args);
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

function parse(ctx: Context, path: string, contents: string): Module {
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

    function parseStmt(): Expr {
        const expr = parseExpr();
        expectDelim();
        return expr;
    }

    function parseBlock(): Block {
        const m = mark();
        expect('{');
        skipDelim();
        const stmts: Expr[] = [];
        while (!consume('}')) {
            stmts.push(parseStmt());
        }
        return new Block(m, stmts);
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
            case '[': {
                const exprs = parseJoin('[', ']', ',', parseExpr);
                return new ListDisplay(m, exprs);
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
    print([1, 2, 3])
    `);
    module.eval(ctx);
}
