package www.three

import www.JSWrapper
import www.JSObject

class Three: JSWrapper {
    val _obj : JSObject
    def cls(): JSObject = js!(JSObject, "Object")
    def get(): Self = js!(JSObject, "THREE").unsafeCast()
}
