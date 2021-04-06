package www.dom

import www.dom.HTMLElement
import www.JSObject

class HTMLInputElement : HTMLElement {
    static val tagName = "input"
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "HTMLInputElement")

    def __get_type(self): String = js0!(self, ".type")
    def __set_type(self, type: String) = setField("type", type)
    def __get_value(self): String = js0!(self, ".value")
    def __set_value(self, value: String) { setField("value", value) }
    def __get_checked(self): Bool = js0!(self, ".checked")
    def __set_checked(self, value: Bool) = setField("checked", value)
}
