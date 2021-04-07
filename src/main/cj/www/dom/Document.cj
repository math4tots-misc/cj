package www.dom

import www.dom.HTMLBodyElement
import www.dom.GlobalEventHandlers
import www.dom.Element
import www.JSObject
import www.JSWrapper

class Document : JSWrapper, GlobalEventHandlers {
    val _obj : JSObject
    def cls(): JSObject = js!(JSObject, "Document")

    def get(): Self = js!(Self, "document")

    def __get_title(self: Self): String = js0!(self, ".title")
    def __set_title(self: Self, title: String) =  js0!(self, ".title=", title)

    def __get_body(self): HTMLBodyElement = js0!(self, ".body")

    def createElement[R: Element](self): R = call("createElement", R.tagName)

    def getElementBydId[R: Element](self: Self, id: String): R = js0!(
        self, ".getElementBydId(", id, ")")
}
