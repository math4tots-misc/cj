package cjx.js.web

import cjx.js.web.GlobalEventHandlers
import cjx.js.web.Element

trait HTMLElement : Element, GlobalEventHandlers {
    def __get_innerText(self): String = self.field("innerText").unsafeCast()
    def __set_innerText(self, t: String) = self.setField("innerText", t)
}
