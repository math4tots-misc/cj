import * as fs from "fs";
import * as pat from "path";
import { SourceNode } from "source-map";

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
]);
const SYMBOLS = [
    '.',
    '++',
    '=',
    '+',
].sort().reverse();

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
        if (ch === '"') {
            while (i < s.length && s[i] !== '"') {
                if (s[i] === '\\') {
                    incr();
                }
                incr();
            }
            incr();
            const value: string = JSON.parse(s.substring(start, i));
            addTok(TTSTR, value);
            continue;
        }
        if (ch.match(/[a-zA-Z_]/)) {
            while (i < s.length && s[i].match(/[a-zA-Z0-9_]/)) {
                incr();
            }
            const value = s.substring(start, i);
            if (KEYWORDS.has(value)) {
                addTok(value);
            } else {
                addTok(TTID, value);
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
    scope: Scope
    constructor(scope: Scope | null = null) {
        this.scope = scope || ROOT;
    }
    error(message: string) {
        return new MError(message, this.stack);
    }
    checkArgc(args: Value[], argc: number) {
        if (args.length !== argc) {
            throw this.error("Expected " + argc + " args but got " + args.length);
        }
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

const ROOT: Scope = Object.create(null);
ROOT['print'] = new Entry(false, (ctx, self, args) => {
    ctx.checkArgc(args, 1);
    console.log(args[0]);
    return null;
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
        const newScope: Scope = Object.create(oldScope);
        ctx.scope = newScope;
        let last: Value = null;
        for (const expr of this.exprs) {
            last = expr.eval(ctx);
        }
        ctx.scope = oldScope;
        return newScope;
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
        ctx.scope = Object.create(oldScope);
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
        entry.value = this.valexpr.eval(ctx);
        return null;
    }
}

class DeclVar extends Expr {
    readonly mutable: boolean
    readonly name: string
    readonly valexpr: Expr
    constructor(mark: Mark, mutable: boolean, name: string, valexpr: Expr) {
        super(mark);
        this.mutable = mutable;
        this.name = name;
        this.valexpr = valexpr;
    }
    eval(ctx: Context) {
        if (Object.prototype.hasOwnProperty.call(ctx.scope, this.name)) {
            ctx.stack.push(this.mark);
            throw ctx.error("Variable '" + this.name + "' is already declared in this scope");
        }
        const entry = new Entry(this.mutable, this.valexpr.eval(ctx));
        ctx.scope[this.name] = entry;
        return null;
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

function callm(ctx: Context, owner: Value, methodName: string, args: Value[]) {
    switch (typeof owner) {
        case 'number': {
            switch (methodName) {
                case '__add': return owner + castNum(ctx, args[0]);
                case '__sub': return owner - castNum(ctx, args[0]);
                case '__mul': return owner * castNum(ctx, args[0]);
                case 'str':case 'repr': return '' + owner;
            }
            break;
        }
        case 'string': {
            switch (methodName) {
                case '__add': return owner + castStr(ctx, args[0]);
                case 'str': return owner;
                case 'repr': return JSON.stringify(owner);
            }
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
                        if (owner.length === 0) { throw ctx.error("Pop from empty array") }
                        return owner.pop();
                    }
                }
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
        case '.': case '(': return 150;
        default: return -1;
    }
}

function parse(ctx: Context, path: string, contents: string): Module {
    path = pat.normalize(path);
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

    function parseExprPr(precedence: number): Expr {
        let expr = parseAtom();
        let tokprec = precof(peek().type);
        while (precedence < tokprec) {
            const m = mark();
            switch (peek().type) {
                case '.': {
                    next();
                    const args = parseArgs();
                    const name = expect(TTID).value as string;
                    expr = mcall(m, expr, name, args);
                    break;
                }
                case '(': {
                    const args = parseArgs();
                    expr = fcall(m, expr, args);
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
    const module = parse(ctx, '<test>', `
    # val x = 10
    # print("x = " + x.repr())
    print("hello world")
    `);
    module.eval(ctx);
}
