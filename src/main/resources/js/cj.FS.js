class MC$cj$FS {
    M$__get_sep() {
        return require('path').sep;
    }
    M$readFile(p) {
        return require('fs').readFileSync(p, 'utf-8');
    }
    M$readFileBytes(p) {
        const b = require('fs').readFileSync(p);
        return MO$cj$Buffer.fromBufferSlice(b.buffer, b.byteOffset, b.byteLength);
    }
    M$writeFile(p, data) {
        const path = require('path');
        const fs = require('fs');
        const dirname = path.dirname(p);
        fs.mkdirSync(dirname, { recursive: true });
        fs.writeFileSync(p, data);
    }
    M$writeFileBytes(p, data) {
        this.M$writeFile(p, new DataView(data[0].buffer, 0, data[2]));
    }
}
