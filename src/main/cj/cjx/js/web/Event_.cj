package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSObject
import cjx.js.web.Event

class Event_: Event {
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("Event")
}
