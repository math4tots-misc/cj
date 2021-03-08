package www.dom

import www.dom.Window
import www.JSObject
import www.dom.HTMLElement

class HTMLButtonElement : HTMLElement {
    static val tagName = "button"
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("HTMLButtonElement")
}
