package cj.js.web

import cj.js.web.GlobalEventHandlers
import cj.js.JSObject
import cj.js.web.Web
import cj.js.JSWrapper

class Window : JSWrapper, GlobalEventHandlers {
    val _obj : JSObject
    def cls(): JSObject = Web.windowClass()

    def get(): Self = Web.window()
    def alert(self: Self, message: String) = self.call("alert", message)

    def requestAnimationFrame(self: Self, f: Fn[Double, Unit]) = (
        self.call("requestAnimationFrame", f))

    def __get_innerWidth(self: Self): Int = self.field("innerWidth").unsafeCast()
    def __get_innerHeight(self: Self): Int = self.field("innerHeight").unsafeCast()
}
