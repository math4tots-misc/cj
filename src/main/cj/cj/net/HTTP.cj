package cj.net

import cj.Uint8Array
import cj.Buffer

native class HTTP {
    ## Dead simple HTTP GET request (response body is processed as UTF-8)
    def get(url: String): Promise[String]

    def getUint8Array(url: String): Promise[Uint8Array]
}
