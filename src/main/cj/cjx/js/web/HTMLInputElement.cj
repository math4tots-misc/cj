package cjx.js.web

import cjx.js.web.Window
import cjx.js.web.HTMLElement
import cjx.js.JSObject

class HTMLInputElement : HTMLElement {
    static val tagName = "input"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLInputElement")

    def __get_type(self): String = field("type").unsafeCast()
    def __set_type(self, type: String) = setField("type", type)
    def __get_value(self): String = field("value").unsafeCast()
    def __set_value(self, value: String) { setField("value", value) }
    def __get_checked(self): Bool = field("checked").unsafeCast()
    def __set_checked(self, value: Bool) = setField("checked", value)
}
