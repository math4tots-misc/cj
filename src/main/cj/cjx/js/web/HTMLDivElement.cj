package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSObject
import cjx.js.web.HTMLElement

class HTMLDivElement : HTMLElement {
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("HTMLDivElement")
}
