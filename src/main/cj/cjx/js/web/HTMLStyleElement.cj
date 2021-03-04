package cjx.js.web

import cjx.js.JSObject
import cjx.js.web.Window
import cjx.js.web.HTMLElement

class HTMLStyleElement : HTMLElement {
    static val tagName = "style"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLStyleElement")
}
