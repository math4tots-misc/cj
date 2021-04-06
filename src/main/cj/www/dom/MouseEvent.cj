package www.dom

import www.dom.UIEvent

trait MouseEvent: UIEvent {
    def __get_button(self: Self): Int = js0!(self, ".button")
    def __get_clientX(self: Self): Double = js0!(self, ".clientX")
    def __get_clientY(self: Self): Double = js0!(self, ".clientY")
}
