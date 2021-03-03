package cjx.js.three

import cjx.js.JSObject
import cjx.js.web.Window

class Three {
    def get(): JSObject = Window.get().field("THREE")
}
