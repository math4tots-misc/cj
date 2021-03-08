package www.dom

import www.dom.Window
import www.JSObject
import www.dom.HTMLElement

class HTMLScriptElement : HTMLElement {
    static val tagName = "script"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLScriptElement")

    def __get_type(self: Self): String = self.field("type").unsafeCast()

    def __get_text(self: Self): String = self.field("text").unsafeCast()
}
