package www.dom

import www.JSObject
import www.dom.HTMLElement

class HTMLDivElement : HTMLElement {
    static val tagName = "div"
    val _obj : JSObject
    def cls(): JSObject = js!(JSObject, "HTMLDivElement")
}
