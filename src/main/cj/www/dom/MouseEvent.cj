package www.dom

import www.dom.UIEvent

trait MouseEvent: UIEvent {
    def __get_button(self: Self): Int = self.field("button").unsafeCast()
    def __get_clientX(self: Self): Double = self.field("clientX").unsafeCast()
    def __get_clientY(self: Self): Double = self.field("clientY").unsafeCast()
}
