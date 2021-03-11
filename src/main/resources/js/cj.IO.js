class MC$cj$IO {
    M$debug(TV$T, t) {
        console.log(t);
    }
    M$printstr(s) {
        if (typeof process !== 'undefined') {
            process.stdout.write(s);
        } else {
            console.log(s);
        }
    }
    M$printlnstr(s) {
        console.log(s);
    }
    M$eprintlnstr(s) {
        console.error(s);
    }
    M$panicstr(s) {
        throw new Error(s);
    }
    M$input() {
        const fs = require('fs');
        return fs.readFileSync(0, {encoding: 'utf-8'});
    }
}
