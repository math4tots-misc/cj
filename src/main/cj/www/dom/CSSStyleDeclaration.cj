package www.dom

import www.JSObject
import www.JSWrapper

class CSSStyleDeclaration: JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "CSSStyleDeclaration")
    def __set_width(self, desc: String) = js0!(self, ".width=", desc)
    def __set_height(self, desc: String) = js0!(self, ".height=", desc)
    def __set_borderStyle(self, desc: String) = setField("border-style", desc)
    def __set_textAlign(self, desc: String) = setField("text-align", desc)
    def __set_margin(self, desc: String) = js0!(self, ".margin=", desc)
    def __set_border(self, desc: String) = js0!(self, ".border=", desc)
    def __set_padding(self, desc: String) = js0!(self, ".padding=", desc)
    def __set_fontWeight(self, desc: String) = setField("font-weight", desc)
    def __set_display(self, desc: String) = js0!(self, ".display=", desc)
}
