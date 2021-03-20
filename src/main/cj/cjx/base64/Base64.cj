package cjx.base64

import cj.Uint8Array
import cj.BufferLike

native class Base64 {

    ## Encode a string, treating it as a sequence of byte values, to a base64 string (aka btoa)
    def encodeString(b: String): String {
        if js!(Bool, "inBrowser") {
            # browser
            js!(String, "btoa(", b, ")")
        } else {
            # nodejs
            js!(String, "Buffer.from(", b, ").toString('base64')")
        }
    }

    ## Encode a buffer bytes to a base64 string (aka btoa)
    def encode[B: BufferLike](b: B): String {
        if js!(Bool, "inBrowser") {
            # browser
            js!(String, "btoa(String.fromCharCode(...", b.bytes(), "))")
        } else {
            # nodejs
            js!(String, "Buffer.from(",
                b.buffer, ",", b.byteOffset, ",", b.byteLength, ").toString('base64')")
        }
    }

    ## Decode a base64 string into a Uint8Array (aka atob)
    def decode(s: String): Uint8Array {
        if js!(Bool, "inBrowser") {
            # browser
            js!(Uint8Array, "new TextEncoder().encode(atob(", s, "))")
        } else {
            # nodejs
            js!(Uint8Array, "Buffer.from(", s, ",'base64')")
        }
    }
}
