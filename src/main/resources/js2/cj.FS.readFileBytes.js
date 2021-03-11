//! cj.DynamicBuffer.js
function cj$FS$readFileBytes(p) {
    const b = require('fs').readFileSync(p);
    return cj$DynamicBuffer.fromBufferSlice(b.buffer, b.byteOffset, b.byteLength);
}
