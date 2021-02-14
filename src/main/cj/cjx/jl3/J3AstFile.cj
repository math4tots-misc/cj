package cjx.jl3

import cjx.jl3.J3AstItem
import cjx.jl3.J3Mark

class J3AstFile {

    class Import {
        val mark: J3Mark
        val alias: String
        val name: String
    }

    val mark: J3Mark
    val packageName: String
    val imports: List[Import]
    val items: List[J3AstItem]
}
