package cj.js.web

import cj.js.web.Window
import cj.js.JSObject
import cj.js.web.UIEvent

class MouseEvent : UIEvent {
    val _obj :  JSObject
    def obj(self: Self): JSObject = self._obj
    def cls() : JSObject = Window.get().field("MouseEvent")

    def __get_button(self: Self): Int = self.obj().field("button").unsafeCast()
    def __get_clientX(self: Self): Double = self.obj().field("clientX").unsafeCast()
    def __get_clientY(self: Self): Double = self.obj().field("clientY").unsafeCast()
}
