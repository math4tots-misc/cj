package www.dom

import www.JSObject
import www.dom.Window
import www.dom.HTMLElement

class HTMLStyleElement : HTMLElement {
    static val tagName = "style"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLStyleElement")
}
