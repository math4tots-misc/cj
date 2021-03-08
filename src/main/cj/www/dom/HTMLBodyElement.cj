package www.dom

import www.dom.Window
import www.JSObject
import www.dom.HTMLElement

class HTMLBodyElement : HTMLElement {
    static val tagName = "body"
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("HTMLBodyElement")
}
