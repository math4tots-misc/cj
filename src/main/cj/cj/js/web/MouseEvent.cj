package cj.js.web

import cj.js.web.Window
import cj.js.JSObject
import cj.js.web.UIEvent

class MouseEvent : UIEvent {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("MouseEvent")

    def __get_button(self: Self): Int = self.field("button").unsafeCast()
    def __get_clientX(self: Self): Double = self.field("clientX").unsafeCast()
    def __get_clientY(self: Self): Double = self.field("clientY").unsafeCast()
}
