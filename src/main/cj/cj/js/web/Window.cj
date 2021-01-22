package cj.js.web

import cj.js.web.GlobalEventHandlers
import cj.js.JSObject
import cj.js.web.Web
import cj.js.JSWrapper

class Window : JSWrapper, GlobalEventHandlers {
    val _obj : JSObject

    def cls(): JSObject = Web.windowClass()
    def get(): Self = Web.window()

    def obj(self: Self): JSObject = self._obj
}
