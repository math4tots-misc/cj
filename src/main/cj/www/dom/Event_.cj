package www.dom

import www.JSObject
import www.dom.Event

class Event_: Event {
    val _obj : JSObject
    def cls(): JSObject = js!(JSObject, "Event")
}
