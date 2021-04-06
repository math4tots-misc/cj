package www.dom

import www.JSObject
import www.JSWrapper

class DOMRect: JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "DragEvent")
    def __get_x(self): Double = js0!(self, ".x")
    def __get_y(self): Double = js0!(self, ".y")
    def __get_width(self): Double = js0!(self, ".width")
    def __get_height(self): Double = js0!(self, ".height")
    def __get_top(self): Double = js0!(self, ".top")
    def __get_right(self): Double = js0!(self, ".right")
    def __get_bottom(self): Double = js0!(self, ".bottom")
    def __get_left(self): Double = js0!(self, ".left")
}
