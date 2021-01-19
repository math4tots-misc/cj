const stack = [];

function printStackTrace() {
    for (const i of stack) {
        const filename = filenameData[markData[3 * i]];
        const line = markData[3 * i + 1];
        const column = markData[3 * i + 2];
        console.log(`  in ${filename}:${line}:${column}`);
    }
}

function call(i, f) {
    stack.push(i);
    const ret = f();
    stack.pop();
    return ret;
}
