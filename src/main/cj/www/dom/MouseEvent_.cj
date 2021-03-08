package www.dom

import www.dom.MouseEvent
import www.dom.Window
import www.JSObject

class MouseEvent_ : MouseEvent {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("MouseEvent")
}
