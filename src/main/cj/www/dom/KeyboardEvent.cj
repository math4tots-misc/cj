package www.dom

import www.JSObject
import www.dom.UIEvent

class KeyboardEvent : UIEvent {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "MouseEvent")

    def __get_altKey(self: Self): Bool = js0!(self, ".altKey")
    def __get_code(self: Self): String = js0!(self, ".code")
    def __get_ctrlKey(self: Self): Bool = js0!(self, ".ctrlKey")
    def __get_key(self: Self): String = js0!(self, ".key")
    def __get_shiftKey(self: Self): Bool = js0!(self, ".shiftKey")
}
