package cjx.js.web

import cjx.js.web.Window
import cjx.js.web.HTMLElement
import cjx.js.JSObject

class HTMLInputElement : HTMLElement {
    static val tagName = "input"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLInputElement")

    def __get_value(self): String = _obj.field("value").unsafeCast()
    def __set_value(self, value: String) { _obj.setField("value", value) }
}
