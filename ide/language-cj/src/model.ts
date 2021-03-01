import * as vscode from 'vscode';

export const IMPORT_EXEMPT_CLASSES = new Set([
    "cj.Any",
    "cj.Assert",
    "cj.Bool",
    "cj.Char",
    "cj.Default",
    "cj.Double",
    "cj.Eq",
    "cj.Fn0",
    "cj.Fn1",
    "cj.Fn2",
    "cj.Fn3",
    "cj.Fn4",
    "cj.Hash",
    "cj.Int",
    "cj.IO",
    "cj.Iterable",
    "cj.Iterator",
    "cj.List",
    "cj.Map",
    "cj.NonNull",
    "cj.NoReturn",
    "cj.Nullable",
    "cj.Ord",
    "cj.Promise",
    "cj.Repr",
    "cj.Set",
    "cj.String",
    "cj.ToBool",
    "cj.ToChar",
    "cj.ToDouble",
    "cj.ToInt",
    "cj.ToList",
    "cj.ToString",
    "cj.Tuple2",
    "cj.Tuple3",
    "cj.Tuple4",
    "cj.Unit",
]);

export class OpenDocument {
    words: Set<string>

    constructor() {
        this.words = new Set();
    }
}

/**
 * Parses a file system path and returns the triple:
 *  - source root path (i.e. path ending in '/src/main/cj/' or '/src/main/cj-js/')
 *  - package name (e.g. 'cjx.foobar')
 *  - class name (e.g. Nullable)
 *
 * If the path is invalid, returns null
 */
export function parseUnixPath(unixpath: string): [string, string, string] | null {

    if (!unixpath.endsWith('.cj')) {
        return null;
    }

    unixpath = unixpath.substring(0, unixpath.length - '.cj'.length);

    for (const component of [
            '/src/main/cj/',
            '/src/main/cj-js/',
            '/src/test/cj/',
            '/src/test/cj-js/']) {
        const i = unixpath.lastIndexOf(component);
        if (i === -1) {
            continue;
        }
        const srcroot = unixpath.substring(0, i + component.length);
        const relpath = unixpath.substring(i + component.length);
        const j = relpath.lastIndexOf('/');
        const pkg = relpath.substring(0, j).replace(/\//g, '.');
        const clsname = relpath.substring(j + 1);
        return [srcroot, pkg, clsname];
    }

    return null;
}

function normalizePath(path: string): string {
    while (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
    }
    return path;
}

/**
 * Parses a file system path and returns the triple:
 *  - source root path (i.e. path ending in '/src/main/cj/' or '/src/main/cj-js/')
 *  - package name (e.g. 'cjx.foobar')
 *  - class name (e.g. Nullable)
 *
 * If the path is invalid, returns null
 */
export function parseSourceUri(uri: vscode.Uri): [string, string, string] | null {
    return parseUnixPath(uri.path);
}


class Trie<T> {
    root: TrieNode<T>
    constructor() {
        this.root = new TrieNode();
    }
    has(key: string): boolean {
        return this.get(key) !== null;
    }
    get(key: string): T | null {
        return this.root.get(key, 0);
    }
    set(key: string, value: T): boolean {
        return !!this.root.set(key, 0, value);
    }
    remove(key: string): T | null {
        return this.root.remove(key, 0);
    }
    [Symbol.iterator]() {
        return this.root[Symbol.iterator]();
    }
    filterWithPrefix(prefix: string): IterableIterator<T> {
        let node: TrieNode<T> = this.root;
        for (let i = 0; i < prefix.length; i++) {
            const childNode = node.map.get(prefix[i]);
            if (childNode === undefined) {
                return [][Symbol.iterator]();
            }
            node = childNode;
        }
        return node[Symbol.iterator]();
    }
}


class TrieNode<T> {
    size: number
    value: T | null
    map: Map<string, TrieNode<T>>

    constructor() {
        this.size = 0;
        this.value = null;
        this.map = new Map();
    }

    get(key: string, index: number): T | null {
        if (index === key.length) {
            return this.value;
        } else if (index < key.length) {
            const child = this.map.get(key[index]);
            if (child === undefined) {
                return null;
            } else {
                return child.get(key, index + 1);
            }
        } else {
            return null;
        }
    }

    set(key: string, index: number, value: T): boolean {
        if (index === key.length) {
            if (this.value !== null) {
                this.value = value;
                return false;
            } else {
                this.value = value;
                this.size += 1;
                return true;
            }
        } else if (index < key.length) {
            const ch = key[index];
            if (!this.map.has(ch)) {
                this.map.set(ch, new TrieNode());
            }
            const incr = this.map.get(ch)!.set(key, index + 1, value);
            this.size += incr ? 1 : 0;
            return incr;
        } else {
            return false;
        }
    }

    remove(key: string, index: number): T | null {
        if (index === key.length) {
            if (this.value != null) {
                const ret = this.value;
                this.value = null;
                this.size -= 1;
                return ret;
            } else {
                return null;
            }
        } else if (index < key.length) {
            const ch = key[index];
            const child = this.map.get(ch);
            if (child === undefined) {
                return null;
            }
            const ret = child.remove(key, index + 1);
            if (child.size === 0) {
                this.map.delete(ch);
            }
            this.size -= 1;
            return ret;
        } else {
            return null;
        }
    }

    *[Symbol.iterator](): IterableIterator<T> {
        if (this.value !== null) {
            yield this.value;
        }
        for (const child of Array.from(this.map).sort().map(pair => pair[1])) {
            for (const item of child) {
                yield item;
            }
        }
    }
}

/**
 * Set with repeats allowed
 */
class RCSet<T> {
    map: Map<T, number>

    constructor() {
        this.map = new Map();
    }

    has(key: T): boolean {
        return this.map.has(key);
    }

    add(key: T) {
        const rc = this.map.get(key);
        if (rc !== undefined) {
            this.map.set(key, rc + 1);
        } else {
            this.map.set(key, 1);
        }
    }

    addAll(keys: Iterable<T>) {
        for (const key of keys) {
            this.add(key);
        }
    }

    remove(key: T) {
        const rc = this.map.get(key);
        if (rc !== undefined) {
            if (rc === 1) {
                this.map.delete(key);
            } else {
                this.map.set(key, rc - 1);
            }
        }
    }

    removeAll(keys: Iterable<T>) {
        for (const key of keys) {
            this.remove(key);
        }
    }

    [Symbol.iterator]() {
        return this.map.keys();
    }
}

function parseItem(s: string): Item {
    const re = /#[^\n]*|\\{|\\}|\b(def|val|var|class|union|trait|case)\s+\w+|\b(import|package)\s+[\.\w]+|\w+\s*:?|"([^"]|\\\")*"|[^\s\w"]+/g;
    let depth = 0;
    let arr;
    let pkg = "";
    let shortName = "";
    const imports = new Trie<string>();
    const methodNames = new Trie<string>();
    const propertyNames = new Trie<string>();
    const fieldNames = new Trie<string>();
    const localNames = new Trie<string>();
    const nestedItemNames = new Trie<string>();
    while ((arr = re.exec(s)) !== null) {
        const x = arr[0];
        if (x.startsWith('#') || x.startsWith('"') || x.startsWith("'")) {
            continue;
        }
        switch (x) {
            case '{':
                depth++;
                break;
            case '}':
                depth--;
                break;
            default: {
                const parts = /^\b(def|val|var|class|union|trait|case|import|package|)\b\s*([\w\.]+)\s*:?/.exec(x);
                if (parts !== null) {
                    const [, kind, name] = parts;
                    switch (kind) {
                        case 'package':
                            if (pkg === "") {
                                pkg = name;
                            }
                            break;
                        case 'import':
                            imports.set(name, name);
                            break;
                        case 'def':
                            methodNames.set(name, name);
                            if (name.startsWith("__get_")) {
                                const propertyName = name.substring("__get_".length);
                                propertyNames.set(propertyName, propertyName);
                            }
                            break;
                        case 'val':
                        case 'var':
                        case 'case':
                            if (depth === 1) {
                                fieldNames.set(name, name);
                            } else {
                                localNames.set(name, name);
                            }
                            break;
                        case 'class':
                        case 'union':
                        case 'trait':
                            if (shortName === "") {
                                shortName = name;
                            } else {
                                nestedItemNames.set(name, name);
                            }
                            break;
                        default:
                            if (/[a-z_]\w*/.test(name)) {
                                localNames.set(name, name);
                            }
                            break;
                    }
                }
                break;
            }
        }
    }
    return new Item(
        pkg, shortName, imports, methodNames, propertyNames, fieldNames, localNames, nestedItemNames);
}

export class Item {
    readonly pkg: string
    readonly shortName: string
    readonly imports: Trie<string>
    readonly methodNames: Trie<string>
    readonly propertyNames: Trie<string>
    readonly fieldNames: Trie<string>
    readonly localNames: Trie<string>
    readonly nestedItemNames: Trie<string>

    constructor(
            pkg: string,
            shortName: string,
            imports: Trie<string>,
            methodNames: Trie<string>,
            propertyNames: Trie<string>,
            fieldNames: Trie<string>,
            localNames: Trie<string>,
            nestedItemNames: Trie<string>) {
        this.pkg = pkg;
        this.shortName = shortName;
        this.imports = imports;
        this.methodNames = methodNames;
        this.propertyNames = propertyNames;
        this.fieldNames = fieldNames;
        this.localNames = localNames;
        this.nestedItemNames = nestedItemNames;
    }

    toString() {
        return (
            `Item("${this.pkg}", "${this.shortName}", ` +
            `"[${Array.from(this.imports)}]", ` +
            `[${Array.from(this.methodNames)}], ` +
            `[${Array.from(this.fieldNames)}])`
        );
    }
}

export class World {
    readonly fs: vscode.FileSystem
    readonly sourceRoots: Set<string>
    readonly shortNameToQualifiedNames: Trie<[string, Set<string>]>
    readonly qualifiedNameToUri: Map<string, vscode.Uri>
    readonly qualifiedNameToItem: Trie<Item>
    readonly allMethodNames: RCSet<string>
    readonly allPropertyNames: RCSet<string>
    readonly allFieldNames: RCSet<string>
    readonly allNestedItemNames: RCSet<string>
    _allKnownItemsInitialized: boolean

    constructor(fs: vscode.FileSystem) {
        this.fs = fs;
        this.sourceRoots = new Set();
        this.shortNameToQualifiedNames = new Trie();
        this.qualifiedNameToUri = new Map();
        this.qualifiedNameToItem = new Trie();
        this.allMethodNames = new RCSet();
        this.allPropertyNames = new RCSet();
        this.allFieldNames = new RCSet();
        this.allNestedItemNames = new RCSet();
        this._allKnownItemsInitialized = false;
    }

    getAllQualifiedNames(): string[] {
        return Array.from(this.qualifiedNameToUri.keys());
    }

    async addSourceRoot(sourceRoot: string): Promise<void> {
        sourceRoot = normalizePath(sourceRoot);
        if (!this.sourceRoots.has(sourceRoot)) {
            this.sourceRoots.add(sourceRoot);
            await this._processSourceRoot(sourceRoot);
        }
    }

    async _processSourceRoot(sourceRoot: string) {
        console.log(`_processSourceRoot(${sourceRoot})`);
        this.sourceRoots.add(sourceRoot);
        const stack = [vscode.Uri.file(sourceRoot)];
        const otherPromises: Promise<Item>[] = [];
        while (stack.length > 0) {
            const uri = stack.pop()!;
            for (const [name, type] of await this.fs.readDirectory(uri)) {
                const child = vscode.Uri.joinPath(uri, name);
                if (type === vscode.FileType.Directory) {
                    stack.push(child);
                } else if (type === vscode.FileType.File && name.endsWith(".cj")) {
                    const triple = parseSourceUri(child);
                    if (triple !== null) {
                        const [, pkg, shortName] = triple;
                        const qualifiedName = pkg + '.' + shortName;
                        this._registerShortName(shortName, qualifiedName);
                        this.qualifiedNameToUri.set(qualifiedName, child);
                        otherPromises.push(this.refreshItem(qualifiedName));
                    }
                }
            }
        }

        for (const promise of otherPromises) {
            await promise;
        }
    }

    _registerShortName(shortName: string, qualifiedName: string) {
        let pair = this.shortNameToQualifiedNames.get(shortName);
        if (pair === null) {
            pair = [shortName, new Set()];
            this.shortNameToQualifiedNames.set(shortName, pair);
        }
        pair[1].add(qualifiedName);
    }

    getItemOrNull(qualifiedName: string): Item | null {
        const item = this.qualifiedNameToItem.get(qualifiedName);
        if (item === null) {
            this.getItem(qualifiedName).catch(e => {
                console.log(`#### getItem failed ${e}`);
            });
            return null;
        } else {
            return item;
        }
    }

    async getItem(qualifiedName: string): Promise<Item> {
        const item = this.qualifiedNameToItem.get(qualifiedName);
        if (item) {
            return item;
        } else {
            return await this.refreshItem(qualifiedName);
        }
    }

    async refreshItemWithUri(uri: vscode.Uri) {
        const triple = parseSourceUri(uri);
        if (triple === null) {
            return;
        }
        const [, pkg, clsname] = triple;
        const qualifiedName = `${pkg}.${clsname}`;
        this.qualifiedNameToUri.set(qualifiedName, uri);
        this.refreshItem(qualifiedName);
    }

    async refreshItem(qualifiedName: string): Promise<Item> {
        // If there's nothing there, put in a dummy value to prevent spurious refreshes.
        if (!this.qualifiedNameToItem.has(qualifiedName)) {
            this.qualifiedNameToItem.set(qualifiedName, parseItem(""));
        }
        const newItem = await this._getItemUncached(qualifiedName);
        const oldItem = this.qualifiedNameToItem.get(qualifiedName);
        if (oldItem) {
            // "release" item members
            this.allFieldNames.removeAll(oldItem.fieldNames);
            this.allNestedItemNames.removeAll(oldItem.nestedItemNames);
            this.allMethodNames.removeAll(oldItem.methodNames);
            this.allPropertyNames.removeAll(oldItem.propertyNames);
        }
        // "retain" item members
        this.allFieldNames.addAll(newItem.fieldNames);
        this.allNestedItemNames.addAll(newItem.nestedItemNames);
        this.allMethodNames.addAll(newItem.methodNames);
        this.allPropertyNames.addAll(newItem.propertyNames);
        this.qualifiedNameToItem.set(qualifiedName, newItem);
        const shortName = qualifiedName.substring(qualifiedName.lastIndexOf('.') + 1);
        this._registerShortName(shortName, qualifiedName);
        return newItem;
    }

    async _getItemUncached(qualifiedName: string): Promise<Item> {
        const uri = this.qualifiedNameToUri.get(qualifiedName);
        if (uri === undefined) {
            console.log(`URI for ${qualifiedName} not found => [${Array.from(this.qualifiedNameToUri.keys())}]`);
            return parseItem("");
        }
        const buffer = Buffer.from(await this.fs.readFile(uri));
        return parseItem(buffer.toString('utf-8'));
    }
}
