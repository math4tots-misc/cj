package cjx.js.web

import cjx.js.JSWrapper

trait Event : JSWrapper {
    def preventDefault(self) = call("preventDefault")
}
