package www.wa

import www.JSObject

class WebAssembly {
    def field(key: String): JSObject = js!(JSObject, "WebAssembly").field(key)
}
