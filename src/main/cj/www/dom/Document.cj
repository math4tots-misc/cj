package www.dom

import www.dom.HTMLBodyElement
import www.dom.GlobalEventHandlers
import www.dom.Element
import www.dom.Web
import www.JSObject
import www.JSWrapper

class Document : JSWrapper, GlobalEventHandlers {
    val _obj : JSObject
    def cls(): JSObject = Web.documentClass()

    def get(): Self = Web.document()

    def __get_title(self: Self): String = self.field("title").unsafeCast()
    def __set_title(self: Self, title: String) = self.setField("title", title)

    def __get_body(self): HTMLBodyElement = field("body").unsafeCast()

    def createElement[R: Element](self): R = call("createElement", R.tagName)

    def getElementBydId[R: Element](self: Self, id: String): R = (
        self.call("getElementById", id))
}