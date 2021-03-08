package www.dom

import www.dom.EventTarget

trait Node : EventTarget {
    def appendChild[C: Node](self, child: C) = _obj.call("appendChild", child)
}
