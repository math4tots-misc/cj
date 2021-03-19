package cjx.cc

import cjx.cc.CCIR.Type
import cjx.cc.CCIR.Node

class CCType {
    static val int: Type = Type.int

    def ptr(inner: Type): Type = Type.ptr(inner)

    def addType(node: Node) {
        if is_set!(node, type) { return () }

        if is_set!(node, lhs) { addType(node.lhs) }
        if is_set!(node, rhs) { addType(node.rhs) }
        if is_set!(node, cond) { addType(node.cond) }
        if is_set!(node, then) { addType(node.then) }
        if is_set!(node, els) { addType(node.els) }
        if is_set!(node, init) { addType(node.init) }
        if is_set!(node, inc) { addType(node.inc) }
        if is_set!(node, body) { for n in node.body { addType(n) } }

        when (node.kind) {
            case add; case sub; case mul; case div; case neg
                case assign { node.type = node.lhs.type }
            case eq; case ne; case lt; case le; case var_
                case int { node.type = int }
            case addr { node.type = ptr(node.lhs.type) }
            case deref {
                if node.lhs.type.kind == Type.Kind.ptr {
                    node.type = node.lhs.type.base
                } else {
                    node.type = int
                }
            }
            else = ()
        }
    }
}
