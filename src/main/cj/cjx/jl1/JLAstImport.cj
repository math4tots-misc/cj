package cjx.jl1

import cjx.jl1.JLMark

@derive(new)
class JLAstImport {
    val mark: JLMark
    val qualifiedName: String
    val alias: String
}
