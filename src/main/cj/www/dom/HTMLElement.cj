package www.dom

import www.dom.CSSStyleDeclaration
import www.dom.GlobalEventHandlers
import www.dom.Element

trait HTMLElement : Element, GlobalEventHandlers {
    def __get_innerText(self): String = js0!(self, ".innerText")
    def __set_innerText(self, t: String) = self.setField("innerText", t)
    def __get_style(self): CSSStyleDeclaration = js0!(self, ".style")
    def __get_offsetWidth(self): Int = js0!(self, ".offsetWidth")
    def __get_offsetHeight(self): Int = js0!(self, ".offsetHeight")
}
