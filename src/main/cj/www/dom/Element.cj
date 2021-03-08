package www.dom

import www.dom.DOMRect
import www.dom.Node

trait Element : Node {
    def __get_tagName(): String
    def __get_innerHTML(self): String = self.field("innerHTML").toString()
    def __set_innerHTML(self, html: String) = self.setField("innerHTML", html)
    def getBoundingClientRect(self): DOMRect = call("getBoundingClientRect").unsafeCast()
    def __get_clientWidth(self): Int = field("clientWidth").unsafeCast()
    def __get_clientHeight(self): Int = field("clientHeight").unsafeCast()
}
