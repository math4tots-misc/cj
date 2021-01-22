package cj.js.web

import cj.js.web.GlobalEventHandlers
import cj.js.web.Element
import cj.js.web.Web
import cj.js.JSObject
import cj.js.JSWrapper

class Document : JSWrapper, GlobalEventHandlers {
    val _obj : JSObject

    def cls(): JSObject = Web.documentClass()
    def obj(self: Self): JSObject = self._obj

    def get(): Self = Web.document()

    def __get_title(self: Self): String = self.field("title").unsafeCast()
    def __set_title(self: Self, title: String) = self.setField("title", title)

    def getElementBydId[R: Element](self: Self, id: String): R = (
        self.call("getElementById", id))
}
