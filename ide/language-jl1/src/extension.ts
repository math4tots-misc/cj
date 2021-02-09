import * as vscode from 'vscode';
import * as model from './model';
import * as path from 'path';


const COMMAND_DUMP_STATUS = 'language-jl1.dumpstatus';
const COMMAND_AUTO_IMPORT = 'language-jl1.autoimport';


export function activate(context: vscode.ExtensionContext) {

    const fs = vscode.workspace.fs;
    const world = new model.World(fs);

    async function addSourceRootAndSiblings(uri: vscode.Uri) {
        const triple = model.parseSourceUri(uri);
        if (triple !== null) {
            const [srcroot,,] = triple;
            await world.addSourceRoot(srcroot);

            const baseroot = path.dirname(path.dirname(srcroot));
            for (const name of ['main/jl1', 'main/jl1-js', 'test/jl1', 'test/jl1-js']) {
                const otherSrcRoot = path.join(baseroot, name);
                await world.addSourceRoot(otherSrcRoot);
            }
        }
    }

    async function lazyInit(documentUri: vscode.Uri) {
        await addSourceRootAndSiblings(documentUri);
        for (const editor of vscode.window.visibleTextEditors) {
            await addSourceRootAndSiblings(editor.document.uri);
        }
    }

    context.subscriptions.push(vscode.commands.registerCommand(COMMAND_DUMP_STATUS, async () => {
        const document = await vscode.workspace.openTextDocument()
        console.log("COMMAND_DUMP_STATUS: " + document.uri);

        const parts: string[] = [];

        const sourceRoots = Array.from(world.sourceRoots).sort();
        parts.push(`SourceRoots ${sourceRoots.length}\n`);
        for (const sourceRoot of sourceRoots) {
            parts.push(`  ${sourceRoot}\n`);
        }
        parts.push('\n');

        const allMethodNames = Array.from(world.allMethodNames).sort();
        parts.push(`Known method names ${allMethodNames.length}\n`);
        for (const methodName of allMethodNames) {
            parts.push(`  ${methodName}\n`);
        }
        parts.push('\n');

        const allPropertyNames = Array.from(world.allPropertyNames).sort();
        parts.push(`Known property names ${allPropertyNames.length}\n`);
        for (const propertyName of allPropertyNames) {
            parts.push(`  ${propertyName}\n`);
        }
        parts.push('\n');

        const allFieldNames = Array.from(world.allFieldNames).sort();
        parts.push(`Known field names ${allFieldNames.length}\n`);
        for (const fieldName of allFieldNames) {
            parts.push(`  ${fieldName}\n`);
        }
        parts.push('\n');

        const qualifiedNames = world.getAllQualifiedNames().sort();
        parts.push(`Known items ${qualifiedNames.length}\n`);
        for (const qaulifiedName of qualifiedNames) {
            parts.push(`  ${qaulifiedName}\n`);
            const item = world.qualifiedNameToItem.get(qaulifiedName);
            if (item === null) {
                parts.push(`    (unprocessed)\n`);
            } else {
                const imports = Array.from(item.imports);
                const fieldNames = Array.from(item.fieldNames);
                const methodNames = Array.from(item.methodNames);
                const propertyNames = Array.from(item.propertyNames);
                const localNames = Array.from(item.localNames);
                parts.push(`    (${item.pkg}) (${item.shortName})\n`);
                parts.push(`    Imports ${imports.length}\n`);
                for (const imp of item.imports) {
                    parts.push(`      ${imp}\n`);
                }
                parts.push(`    FieldNames ${fieldNames.length}\n`);
                for (const fieldName of fieldNames) {
                    parts.push(`      ${fieldName}\n`);
                }
                parts.push(`    MethodNames ${methodNames.length}\n`);
                for (const methodName of methodNames) {
                    parts.push(`      ${methodName}\n`);
                }
                parts.push(`    PropertyNames ${propertyNames.length}\n`);
                for (const propertyName of propertyNames) {
                    parts.push(`      ${propertyName}\n`);
                }
                parts.push(`    LocalNames ${localNames.length}\n`);
                for (const localName of localNames) {
                    parts.push(`      ${localName}\n`);
                }
            }
        }

        const edit = new vscode.WorkspaceEdit();
        edit.insert(document.uri, document.lineAt(0).range.start, parts.join(''));
        vscode.workspace.applyEdit(edit);

        vscode.window.showTextDocument(document);
    }));

    context.subscriptions.push(vscode.commands.registerCommand(COMMAND_AUTO_IMPORT, (qualifiedName: string) => {
        if (model.IMPORT_EXEMPT_CLASSES.has(qualifiedName)) {
            return;
        }
        const document = vscode.window.activeTextEditor?.document;
        if (document === undefined) {
            return;
        }
        {
            const triple = model.parseSourceUri(document.uri);
            if (triple !== null) {
                const [, pkg, clsname] = triple;
                if (qualifiedName === `${pkg}.${clsname}`) {
                    // You don't need to import the item in its own file.
                    return;
                }
            }
        }
        let pkgline = 0;
        let insertLineno = 0;
        let line = document.lineAt(insertLineno).text;
        while (line === '' || line.startsWith('#') || line.startsWith('package ')) {
            if (line.startsWith('package ')) {
                pkgline = insertLineno;
            }
            insertLineno++;
            line = document.lineAt(insertLineno).text.trim();
        }
        const addExtraNewline = !line.startsWith('import ');

        for (let ln = insertLineno; line.startsWith('import '); ln++, line = document.lineAt(ln).text) {
            const match = /import\s+([\w\.]+)/.exec(line);
            if (match !== null && match[1] === qualifiedName) {
                // the import already exists, so there's no need to add an import line
                return;
            }
        }

        if (addExtraNewline && pkgline + 2 < insertLineno) {
            insertLineno = pkgline + 2;
        }

        const edit = new vscode.WorkspaceEdit();
        edit.insert(
            document.uri,
            document.lineAt(insertLineno).range.start,
            `import ${qualifiedName}\n${addExtraNewline ? '\n' : ''}`,
        );
        vscode.workspace.applyEdit(edit);
    }));

    context.subscriptions.push(vscode.workspace.onDidCreateFiles(event => {
        for (const file of event.files) {
            const unixpath = file.path;
            if (unixpath.endsWith(".jl1")) {
                const triple = model.parseSourceUri(file);
                if (triple !== null) {
                    const [, pkg, clsname] = triple;
                    fs.writeFile(file, Buffer.from(`package ${pkg}

class ${clsname} {
}
`, 'utf-8'));
                }
            }
        }
    }));

    context.subscriptions.push(vscode.workspace.onDidSaveTextDocument(document => {
        if (document.languageId !== 'jl1') {
            return undefined;
        }
        world.refreshItemWithUri(document.uri);
    }))

    context.subscriptions.push(vscode.workspace.onDidOpenTextDocument(document => {
        if (document.languageId !== 'jl1') {
            return undefined;
        }
        lazyInit(document.uri);
    }));

    context.subscriptions.push(vscode.workspace.onDidCloseTextDocument(document => {
        if (document.languageId !== 'jl1') {
            return undefined;
        }
    }));

    context.subscriptions.push(vscode.languages.registerCompletionItemProvider('jl1', {
        async provideCompletionItems(document: vscode.TextDocument, position: vscode.Position) {
            try {
                await lazyInit(document.uri);

                const range = document.getWordRangeAtPosition(position);
                const prefix = document.getText(range);
                if (prefix.length === 0) {
                    return undefined;
                }

                const line = document.lineAt(position).text;

                // Don't provide completions in comments
                if (line.trim().startsWith('#')) {
                    return undefined;
                }

                const items: vscode.CompletionItem[] = [];

                let pkg = "";
                let clsname = "";
                {
                    const sourceTriple = model.parseSourceUri(document.uri);
                    if (sourceTriple !== null) {
                        const [, pkg_, clsname_] = sourceTriple;
                        pkg = pkg_;
                        clsname = clsname_;
                    }
                }

                // completion based on class names
                addSourceRootAndSiblings(document.uri);

                for (const [shortName, qualifiedNames] of world.shortNameToQualifiedNames.filterWithPrefix(prefix)) {
                    for (const qualifiedName of qualifiedNames) {
                        const item = new vscode.CompletionItem(shortName);
                        item.detail = qualifiedName;
                        item.command = {
                            command: COMMAND_AUTO_IMPORT,
                            title: 'autoimport',
                            arguments: [qualifiedName],
                        };
                        items.push(item);
                    }
                }

                // completion based on local names
                {
                    const item = world.getItemOrNull(pkg + '.' + clsname);
                    if (item !== null) {
                        for (const name of item.localNames) {
                            items.push(new vscode.CompletionItem(name));
                        }
                    }
                }

                return items;
            } catch (e) {
                console.log(e.stack);
                console.log('ERROR: ' + e);
            }
        }
    }));

    context.subscriptions.push(vscode.languages.registerCompletionItemProvider('jl1', {
        async provideCompletionItems(document: vscode.TextDocument, position: vscode.Position) {
            try {
                await lazyInit(document.uri);

                const line = document.lineAt(position).text;

                // Don't provide completions in comments
                if (line.trim().startsWith('#')) {
                    return undefined;
                }

                const range = document.getWordRangeAtPosition(position);

                const items: vscode.CompletionItem[] = [];

                // completion based on method and field names
                const prefix = range === undefined ? "" : document.getText(range);
                const linePrefix = document.lineAt(position).text.substr(0, position.character);
                if (linePrefix.endsWith('.' + prefix)) {
                    for (const fieldName of world.allFieldNames) {
                        if (fieldName.startsWith(prefix)) {
                            items.push(new vscode.CompletionItem(fieldName));
                        }
                    }
                    for (const methodName of world.allMethodNames) {
                        if (methodName.startsWith(prefix)) {
                            items.push(new vscode.CompletionItem(methodName + '('));
                        }
                    }
                    for (const propertyName of world.allPropertyNames) {
                        if (propertyName.startsWith(prefix)) {
                            items.push(new vscode.CompletionItem(propertyName));
                        }
                    }
                }
                return items;
            } catch (e) {
                console.log(e.stack);
                console.log('' + e);
                throw e;
            }
        }
    }, '.'));
}
