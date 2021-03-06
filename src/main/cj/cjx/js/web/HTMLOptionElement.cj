package cjx.js.web

import cjx.js.web.HTMLElement
import cjx.js.web.Window
import cjx.js.JSObject

class HTMLOptionElement: HTMLElement {
    static val tagName = "option"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLOptionElement")

    def __get_value(self): String = field("value").unsafeCast()
    def __set_value(self, value: String) = setField("value", value)
}
