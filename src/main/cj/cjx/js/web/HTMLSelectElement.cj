package cjx.js.web

import cjx.js.web.HTMLElement
import cjx.js.web.Window
import cjx.js.JSObject

class HTMLSelectElement: HTMLElement {
    static val tagName = "select"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLSelectElement")

    def __get_value(self): String = field("value").unsafeCast()
}
