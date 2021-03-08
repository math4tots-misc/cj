package www.dom

import www.dom.Window
import www.JSObject
import www.dom.Document

native class Web {
    def document(): Document
    def documentClass(): JSObject
    def window(): Window
    def windowClass(): JSObject
}
