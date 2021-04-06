package www.dom

import www.dom.HTMLElement
import www.JSObject

class HTMLSelectElement: HTMLElement {
    static val tagName = "select"
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "HTMLSelectElement")

    def __get_value(self): String = js0!(self, ".value")
}
