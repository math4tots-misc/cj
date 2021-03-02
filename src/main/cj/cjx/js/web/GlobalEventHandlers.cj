package cjx.js.web

import cjx.js.web.KeyboardEvent
import cjx.js.web.MouseEvent
import cjx.js.JSWrapper

trait GlobalEventHandlers : JSWrapper {
    def onclick(self: Self, f: Fn[MouseEvent, Unit]) = self.setField("onclick", f)
    def onkeydown(self: Self, f: Fn[KeyboardEvent, Unit]) = self.setField("onkeydown", f)
}
