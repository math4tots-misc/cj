package cj.js.web

import cj.js.web.Window
import cj.js.JSObject
import cj.js.web.HTMLElement

class HTMLDivElement : HTMLElement {
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("HTMLDivElement")
}
