package cj.js.web

import cj.js.web.GlobalEventHandlers
import cj.js.web.Element

trait HTMLElement : Element, GlobalEventHandlers {
    def __get_innerText(self): String = self.field("innerText").unsafeCast()
    def __set_innerText(self, t: String) = self.setField("innerText", t)
}
