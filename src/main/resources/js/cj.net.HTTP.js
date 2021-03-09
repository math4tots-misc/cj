function HTTPGet(url, type) {
    if (typeof XMLHttpRequest !== 'undefined') {
        return new Promise((resolve, reject) => {
            const request = new XMLHttpRequest();
            request.onreadystatechange = () => {
                if (request.readyState === XMLHttpRequest.DONE) {
                    // local files, status is 0 upon success in Mozilla Firefox
                    const status = request.status;
                    if (status === 0 || (status >= 200 && status < 400)) {
                        switch (type) {
                            case 'string': resolve(request.responseText); break;
                            case 'arraybuffer': resolve(request.response); break;
                            case 'uint8array': resolve(new Uint8Array(request.response)); break;
                            default: reject(new Error("Unrecognized request type " + type)); break;
                        }
                    } else {
                        reject(new Error("XMLHttpRequest error: " + status));
                    }
                }
            }
            switch (type) {
                case 'string': break;
                case 'arraybuffer':
                case 'uint8array':
                    request.responseType = "arraybuffer"; break;
                default: throw new Error("Unrecognized request type " + type);
            }
            request.open("GET", url);
            request.send();
        })
    } else {
        const http = url.startsWith('https://') ? require('https') : require('http');
        return new Promise((resolve, reject) => {
            let ondata, onfinish;
            const onerror = status => reject(new Error(`http request error ${status}`))
            switch (type) {
                case 'string': {
                    let data = '';
                    ondata = chunk => data += chunk
                    onfinish = () => resolve(data)
                    break;
                }
                case 'arraybuffer': {
                    const parts = [];
                    ondata = chunk => parts.push(chunk);
                    onfinish = () => {
                        const buf = Buffer.concat(parts);
                        resolve(buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength));
                    }
                    break;
                }
                case 'uint8array': {
                    const parts = [];
                    ondata = chunk => parts.push(chunk);
                    onfinish = () => resolve(Buffer.concat(parts));
                    break;
                }
                default:
                    throw new Error("Unrecognized request type " + type);
            }
            const request = http.request(url, response => {
                response.on('data', ondata);
                response.on('end', () => {
                    const status = response.statusCode;
                    if (response.complete && status && status >= 200 && status < 400) {
                        onfinish();
                    } else {
                        onerror(status);
                    }
                })
            });
            request.end();
        })
    }
}
class MC$cj$net$HTTP {
    M$get(url) {
        return HTTPGet(url, 'string');
    }
    M$getUint8Array(url) {
        return HTTPGet(url, 'uint8array');
    }
    M$getArrayBuffer(url) {
        return HTTPGet(url, 'arraybuffer');
    }
}
