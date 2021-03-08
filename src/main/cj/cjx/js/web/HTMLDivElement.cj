package cjx.js.web

import cjx.js.web.Window
import www.JSObject
import cjx.js.web.HTMLElement

class HTMLDivElement : HTMLElement {
    static val tagName = "div"
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("HTMLDivElement")
}
