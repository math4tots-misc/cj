package cjx.js.web

import cjx.js.web.Window
import www.JSObject
import cjx.js.web.UIEvent

class KeyboardEvent : UIEvent {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("MouseEvent")

    def __get_altKey(self: Self): Bool = self.field("altKey").unsafeCast()
    def __get_code(self: Self): String = self.field("code").unsafeCast()
    def __get_ctrlKey(self: Self): Bool = self.field("ctrlKey").unsafeCast()
    def __get_key(self: Self): String = self.field("key").unsafeCast()
    def __get_shiftKey(self: Self): Bool = self.field("shiftKey").unsafeCast()
}
