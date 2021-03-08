package www.dom

import www.dom.HTMLElement
import www.dom.Window
import www.JSObject

class HTMLSelectElement: HTMLElement {
    static val tagName = "select"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLSelectElement")

    def __get_value(self): String = field("value").unsafeCast()
}
