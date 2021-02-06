package cjx.jl1

import cjx.jl1.JLAstClass
import cjx.jl1.JLAstImport
import cjx.jl1.JLMark

@derive(new)
class JLAstFile {
    val mark: JLMark
    val packageName: String
    val imports: List[JLAstImport]
    val classes: List[JLAstClass]
}
