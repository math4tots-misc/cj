class MC$cj$net$HTTP {
    M$get(url) {
        if (typeof XMLHTTPRequest !== 'undefined') {
            const request = new XMLHTTPRequest();
            const promise = new Promise((resolve, reject) => {
                request.onreadystatechange = () => {
                    if (request.readyState === XMLHTTPRequest.DONE) {
                        // local files, status is 0 upon success in Mozilla Firefox
                        const status = request.status;
                        if (status === 0 || (status >= 200 && status < 400)) {
                            resolve(request.responseText);
                        } else {
                            reject(new Error("XMLHTTPRequest error: " + status));
                        }
                    }
                };
            });
            request.open("GET", url);
            request.send();
            return promise;
        } else if (url.startsWith("https://")) {
            // nodejs (https)
            const https = require('https');
            const promise = new Promise((resolve, reject) => {
                const request = https.request(url, response => {
                    let data = '';
                    response.on('data', chunk => {
                        data += chunk;
                    });
                    response.on('end', () => {
                        const status = response.statusCode
                        if (response.complete && status && status >= 200 && status < 400) {
                            resolve(data);
                        } else {
                            reject("https.request error: " + status);
                        }
                    });
                });
                request.end();
            });
            return promise;
        } else {
            // nodejs (http)
            const http = require('http');
            const promise = new Promise((resolve, reject) => {
                const request = http.request(url, response => {
                    let data = '';
                    response.on('data', chunk => {
                        data += chunk;
                    });
                    response.on('end', () => {
                        const status = response.statusCode
                        if (response.complete && status && status >= 200 && status < 400) {
                            resolve(data);
                        } else {
                            reject("http.request error: " + status);
                        }
                    });
                });
                request.end();
            });
            return promise;
        }
    }
}
