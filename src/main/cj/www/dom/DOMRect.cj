package www.dom

import www.JSObject
import www.JSWrapper

class DOMRect: JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "DragEvent")
    def __get_x(self): Double = field("x").unsafeCast()
    def __get_y(self): Double = field("y").unsafeCast()
    def __get_width(self): Double = field("width").unsafeCast()
    def __get_height(self): Double = field("height").unsafeCast()
    def __get_top(self): Double = field("top").unsafeCast()
    def __get_right(self): Double = field("right").unsafeCast()
    def __get_bottom(self): Double = field("bottom").unsafeCast()
    def __get_left(self): Double = field("left").unsafeCast()
}
