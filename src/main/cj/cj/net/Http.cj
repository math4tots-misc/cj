package cj.net

import cj.Buffer

native class HTTP {
    ## Dead simple HTTP GET request (response body is processed as UTF-8)
    def get(url: String): Promise[String]
}
