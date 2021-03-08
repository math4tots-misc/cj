package www.dom

import www.dom.Window
import www.dom.MouseEvent
import www.dom.UIEvent
import www.JSObject

class DragEvent: MouseEvent {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("DragEvent")
}
