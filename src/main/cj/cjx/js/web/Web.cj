package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSObject
import cjx.js.web.Document

native class Web {
    def document(): Document
    def documentClass(): JSObject
    def window(): Window
    def windowClass(): JSObject
}
