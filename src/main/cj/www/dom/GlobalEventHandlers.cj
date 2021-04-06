package www.dom

import www.dom.DragEvent
import www.dom.Event
import www.dom.KeyboardEvent
import www.dom.MouseEvent
import www.JSWrapper

trait GlobalEventHandlers : JSWrapper {
    def onclick(self: Self, f: Fn[MouseEvent, Unit]) =  js0!(self, ".onclick=", f)
    def onkeydown(self: Self, f: Fn[KeyboardEvent, Unit]) =  js0!(self, ".onkeydown=", f)
    def onkeyup(self: Self, f: Fn[KeyboardEvent, Unit]) =  js0!(self, ".onkeyup=", f)
    def onchange(self: Self, f: Fn[Event, Unit]) =  js0!(self, ".onchange=", f)
    def ondrop(self: Self, f: Fn[DragEvent, Unit]) =  js0!(self, ".ondrop=", f)
    def ondragover(self: Self, f: Fn[DragEvent, Unit]) =  js0!(self, ".ondragover=", f)
}
