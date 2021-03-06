package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSObject
import cjx.js.web.HTMLElement

@implicit(HTMLElement, _cast)
class HTMLElement_ : HTMLElement {
    static val tagName = "unknown"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLElement")

    def _cast[HTMLElement](t: HTMLElement): Self = __malloc(t)
}
