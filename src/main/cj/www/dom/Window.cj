package www.dom

import www.dom.GlobalEventHandlers
import www.JSObject
import www.JSWrapper

class Window : JSWrapper, GlobalEventHandlers {
    val _obj : JSObject
    def cls(): JSObject = js!(JSObject, "Window")

    def get(): Self = js!(Self, "window")
    def alert(self: Self, message: String) = self.call("alert", message)

    def requestAnimationFrame(self: Self, f: Fn[Double, Unit]) = (
        self.call("requestAnimationFrame", f))

    def __get_innerWidth(self: Self): Int = self.field("innerWidth").unsafeCast()
    def __get_innerHeight(self: Self): Int = self.field("innerHeight").unsafeCast()
}
