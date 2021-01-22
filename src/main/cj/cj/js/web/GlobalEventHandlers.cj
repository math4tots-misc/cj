package cj.js.web

import cj.js.web.KeyboardEvent
import cj.js.web.MouseEvent
import cj.js.JSWrapper

trait GlobalEventHandlers : JSWrapper {
    def onclick(self: Self, f: Fn[MouseEvent, Unit]) = self.obj().setField("onclick", f)
    def onkeydown(self: Self, f: Fn[KeyboardEvent, Unit]) = self.obj().setField("onkeydown", f)
}
