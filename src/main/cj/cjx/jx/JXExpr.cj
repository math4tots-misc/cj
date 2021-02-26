package cjx.jx

import cjx.jx.JXType
import compiler.CJMark

class JXExpr {
    val mark: CJMark
    val prep: Fn[Unit]
    val emit: Fn[Unit]
    var _type: JXType? = null
}
