package www.three

import www.JSWrapper
import www.JSObject
import www.dom.Window

class Three: JSWrapper {
    val _obj : JSObject
    def cls(): JSObject = Window.get().field("Object")
    def get(): Self = Window.get().field("THREE").unsafeCast()
}
