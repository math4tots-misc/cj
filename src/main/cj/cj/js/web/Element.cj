package cj.js.web

import cj.js.web.Node

trait Element : Node {
    def __get_innerHTML(self: Self): String = self.obj().field("innerHTML").toString()
    def __set_innerHTML(self: Self, html: String) = self.obj().setField("innerHTML", html)
}
