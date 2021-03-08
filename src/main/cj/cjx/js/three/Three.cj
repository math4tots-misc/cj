package cjx.js.three

import www.JSWrapper
import www.JSObject
import cjx.js.web.Window

class Three: JSWrapper {
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("Object")
    def get(): Self = Window.get().field("THREE").unsafeCast()
}
