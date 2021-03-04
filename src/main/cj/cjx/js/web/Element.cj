package cjx.js.web

import cjx.js.web.Node

trait Element : Node {
    def __get_tagName(): String
    def __get_innerHTML(self): String = self.field("innerHTML").toString()
    def __set_innerHTML(self, html: String) = self.setField("innerHTML", html)
}
