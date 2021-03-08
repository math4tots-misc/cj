package www.dom

import www.dom.Window
import www.JSObject
import www.dom.HTMLElement

@implicit(HTMLElement, _cast)
class HTMLElement_ : HTMLElement {
    static val tagName = "unknown"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLElement")

    def _cast[HTMLElement](t: HTMLElement): Self = __malloc(t)
}
