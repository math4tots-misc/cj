package www.dom

import www.JSObject
import www.dom.HTMLElement

@implicit(HTMLElement, _cast)
class HTMLElement_ : HTMLElement {
    static val tagName = "unknown"
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "HTMLElement")

    def _cast[HTMLElement](t: HTMLElement): Self = __malloc(t)
}
