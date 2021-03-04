package cjx.js.web

import cjx.js.web.EventTarget

trait Node : EventTarget {
    def appendChild[C: Node](self, child: C) = _obj.call("appendChild", child)
}
