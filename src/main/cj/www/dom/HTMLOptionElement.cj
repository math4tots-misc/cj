package www.dom

import www.dom.HTMLElement
import www.dom.Window
import www.JSObject

class HTMLOptionElement: HTMLElement {
    static val tagName = "option"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLOptionElement")

    def __get_value(self): String = field("value").unsafeCast()
    def __set_value(self, value: String) = setField("value", value)
}
