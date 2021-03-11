package www.dom

import www.dom.MouseEvent
import www.JSObject

class MouseEvent_ : MouseEvent {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "MouseEvent")
}
