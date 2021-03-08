package cjx.js.web

import www.JSWrapper

trait Event : JSWrapper {
    def preventDefault(self) = call("preventDefault")
}
