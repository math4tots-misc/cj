class MC$cj$FS {
    M$readFile(p) {
        return require('fs').readFileSync(p, 'utf-8');
    }
    M$readFileBytes(p) {
        return MO$cj$Buffer.fromBuffer(require('fs').readFileSync(p).buffer);
    }
    M$writeFile(p, data) {
        const path = require('path');
        const fs = require('fs');
        const dirname = path.dirname(p);
        fs.mkdirSync(dirname, { recursive: true });
        fs.writeFileSync(p, data);
    }
    M$writeFileBytes(p, data) {
        this.M$writeFile(p, data[0]);
    }
}