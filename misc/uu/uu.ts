import * as fs from "fs";
import * as pat from "path";


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

class World {
    map: Map<string, Module>
    constructor() {
        this.map = new Map();
    }
    addModule(module: Module) {
        this.map.set(module.path, module);
    }
    getModule(name: string) {
        return this.map.get(name);
    }
}

class Module {
    path: string
    map: Map<string, Item>
    constructor(path: string) {
        this.path = path;
        this.map = new Map();
    }
}

abstract class Item {
    abstract mark: Mark
    abstract name: string
}

class Type extends Item {
    mark: Mark
    name: string
    methodMap: Map<string, Method>
    constructor(mark: Mark, name: string) {
        super();
        this.mark = mark;
        this.name = name;
        this.methodMap = new Map();
    }
}

class Method {
    mark: Mark
    name: String
    constructor(mark: Mark, name: String) {
        this.mark = mark;
        this.name = name;
    }
}

class Scope {
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
        throw new MError("Unrecognized token (" + ch + ")", newMark());
    }
    addTok(TTEOF);
    return toks;
}

function parse(world: World, path: string, contents: string): Module {
    path = pat.normalize(path);
    const module = new Module(path);
    world.addModule(module);
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

    while (!at(TTEOF)) {
    }

    return module;
}
