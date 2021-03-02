package cjx.js.web

import cjx.js.web.GlobalEventHandlers
import cjx.js.JSObject
import cjx.js.web.Web
import cjx.js.JSWrapper

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
