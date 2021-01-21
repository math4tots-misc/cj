package cj.js.web

import cj.js.JSObject
import cj.js.web.Document

native class Web {
    def document(): Document
    def documentClass(): JSObject
}
