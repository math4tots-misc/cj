import * as fs from "fs";
import * as pat from "path";
import { SourceNode } from "source-map";


function assert(cond: number | string | boolean) {
    if (!cond) {
        throw Error("Assertion failed");
    }
}

class Mark {
    path: string
    line: number
    column: number
    constructor(path: string, line: number, column: number) {
        this.path = path;
        this.line = line;
        this.column = column;
    }
    toString() {
        return this.path + ":" + this.line + ":" + this.column;
    }
}

class MError extends Error {
    constructor(message: string, ...marks: Mark[]) {
        super(message + "\n" + marks.map(m => "  " + m).join("\n"));
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
]);
const SYMBOLS = [
    '.',
    '++',
].sort().reverse();

function lex(path: string, contents: string): Token[] {
    const s = contents;
    let i = 0, line = 1, column = 1, lastLine = line, lastColumn = column;
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
        return new Mark(path, lastLine, lastColumn);
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
        lastLine = line;
        lastColumn = column;
        if (i >= s.length) break;
        const start = i;
        let ch = s[i];
        incr();
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
        throw new MError("Unrecognized token " + JSON.stringify(ch), newMark());
    }
    addTok(TTEOF);
    return toks;
}

class Context {
    nodes: SourceNode[]
    constructor() {
        this.nodes = [];
    }
}

function parse(ctx: Context, path: string, contents: string) {
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

    function expect(type: string) {
        if (!at(type)) {
            throw new MError("Expected " + type + " but got " + peek().type, mark());
        }
        return next();
    }

    function parseExpr() {
    }

    const stmts: SourceNode[] = [];
    while (!at(TTEOF)) {
    }

    return new SourceNode(1, 1, path, stmts);
}
