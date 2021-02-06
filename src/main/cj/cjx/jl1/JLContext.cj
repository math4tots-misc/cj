package cjx.jl1

import cjx.jl1.JLIRClass

@derive(new)
class JLContext {
    val classMap: Map[String, JLIRClass] = Map()
}
