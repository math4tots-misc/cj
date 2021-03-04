package cjx.js.web

import cjx.js.web.Window
import cjx.js.web.MouseEvent
import cjx.js.web.UIEvent
import cjx.js.JSObject

class DragEvent: MouseEvent {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("DragEvent")
}
