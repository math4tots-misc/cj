package cjx.js.web

import cjx.js.web.MouseEvent
import cjx.js.web.Window
import www.JSObject

class MouseEvent_ : MouseEvent {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("MouseEvent")
}
