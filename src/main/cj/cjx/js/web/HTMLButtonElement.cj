package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSObject
import cjx.js.web.HTMLElement

class HTMLButtonElement : HTMLElement {
    static val tagName = "button"
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("HTMLButtonElement")
}
