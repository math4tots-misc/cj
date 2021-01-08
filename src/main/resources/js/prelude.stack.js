const stack = [];

function push(i) {
    stack.push(i);
}

function pop(undef, value) {
    stack.pop();
    return value;
}

function printStackTrace() {
    for (const i of stack) {
        const filename = filenameData[markData[3 * i]];
        const line = markData[3 * i + 1];
        const column = markData[3 * i + 2];
        console.log(`  in ${filename}:${line}:${column}`);
    }
}
