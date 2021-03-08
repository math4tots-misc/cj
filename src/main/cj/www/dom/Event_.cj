package www.dom

import www.dom.Window
import www.JSObject
import www.dom.Event

class Event_: Event {
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("Event")
}
