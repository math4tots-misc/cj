package www.dom

import www.JSObject
import www.JSWrapper

class CSSStyleDeclaration: JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "CSSStyleDeclaration")
    def __set_width(self, desc: String) = setField("width", desc)
    def __set_height(self, desc: String) = setField("height", desc)
    def __set_borderStyle(self, desc: String) = setField("border-style", desc)
    def __set_textAlign(self, desc: String) = setField("text-align", desc)
    def __set_margin(self, desc: String) = setField("margin", desc)
    def __set_border(self, desc: String) = setField("border", desc)
    def __set_padding(self, desc: String) = setField("padding", desc)
    def __set_fontWeight(self, desc: String) = setField("font-weight", desc)
    def __set_display(self, desc: String) = setField("display", desc)
}
