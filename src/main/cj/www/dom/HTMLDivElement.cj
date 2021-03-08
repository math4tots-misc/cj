package www.dom

import www.dom.Window
import www.JSObject
import www.dom.HTMLElement

class HTMLDivElement : HTMLElement {
    static val tagName = "div"
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("HTMLDivElement")
}
