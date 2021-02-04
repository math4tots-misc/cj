class MC$cj$IO {
    M$println(TV$T, t) {
        console.log(TV$T.M$toString(t));
    }
    M$print(TV$T, t) {
        if (typeof process !== 'undefined') {
            process.stdout.write(TV$T.M$toString(t));
        } else {
            console.log(TV$T.M$toString(t));
        }
    }
    M$eprintln(TV$T, t) {
        console.error(TV$T.M$toString(t));
    }
    M$panic(TV$T, t) {
        throw new Error(TV$T.M$toString(t));
    }
    M$input() {
        const fs = require('fs');
        return fs.readFileSync(0, {encoding: 'utf-8'});
    }
}
