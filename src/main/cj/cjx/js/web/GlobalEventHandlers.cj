package cjx.js.web

import cjx.js.web.DragEvent
import cjx.js.web.Event
import cjx.js.web.KeyboardEvent
import cjx.js.web.MouseEvent
import www.JSWrapper

trait GlobalEventHandlers : JSWrapper {
    def onclick(self: Self, f: Fn[MouseEvent, Unit]) = self.setField("onclick", f)
    def onkeydown(self: Self, f: Fn[KeyboardEvent, Unit]) = self.setField("onkeydown", f)
    def onkeyup(self: Self, f: Fn[KeyboardEvent, Unit]) = self.setField("onkeyup", f)
    def onchange(self: Self, f: Fn[Event, Unit]) = self.setField("onchange", f)
    def ondrop(self: Self, f: Fn[DragEvent, Unit]) = self.setField("ondrop", f)
    def ondragover(self: Self, f: Fn[DragEvent, Unit]) = self.setField("ondragover", f)
}
