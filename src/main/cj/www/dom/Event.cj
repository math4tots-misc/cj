package www.dom

import www.JSWrapper

trait Event : JSWrapper {
    def preventDefault(self) = call("preventDefault")
}
