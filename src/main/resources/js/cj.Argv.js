class MC$cj$Argv {
    M$__new() {
        if (typeof process === 'undefined') {
            return [];
        } else {
            return process.argv.slice(2);
        }
    }
}