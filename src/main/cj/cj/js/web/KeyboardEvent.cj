package cj.js.web

import cj.js.web.Window
import cj.js.JSObject
import cj.js.web.UIEvent

class KeyboardEvent : UIEvent {
    val _obj :  JSObject
    def obj(self: Self): JSObject = self._obj
    def cls() : JSObject = Window.get().field("MouseEvent")

    def __get_altKey(self: Self): Bool = self.obj().field("altKey").unsafeCast()
    def __get_code(self: Self): String = self.obj().field("code").unsafeCast()
    def __get_ctrlKey(self: Self): Bool = self.obj().field("ctrlKey").unsafeCast()
    def __get_key(self: Self): String = self.obj().field("key").unsafeCast()
    def __get_shiftKey(self: Self): Bool = self.obj().field("shiftKey").unsafeCast()
}
