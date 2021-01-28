class MC$cj$Argv {
    M$new() {
        if (typeof process === 'undefined') {
            return [];
        } else {
            return process.argv.slice(2);
        }
    }
}