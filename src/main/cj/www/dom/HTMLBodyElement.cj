package www.dom

import www.JSObject
import www.dom.HTMLElement

class HTMLBodyElement : HTMLElement {
    static val tagName = "body"
    val _obj : JSObject
    def cls(): JSObject = js!(JSObject, "HTMLBodyElement")
}
