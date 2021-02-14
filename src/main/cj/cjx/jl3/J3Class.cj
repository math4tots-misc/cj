package cjx.jl3

import cjx.jl3.J3Method
import cjx.jl3.J3Field
import cjx.jl3.J3Data
import cjx.jl3.J3Mark

class J3Class: Repr {
    val mark: J3Mark
    val modifiers: List[String]
    val name: String
    val superClass: Nullable[J3Class] = null
    val interfaces: List[J3Class] = []
    var templateName: String = ""
    var templateArgs: List[J3Data] = []
    val fields: List[J3Field] = []
    val methods: List[J3Method] = []
    def isInterface(self): Bool = "interface" in modifiers
    def isUnion(self): Bool = "union" in modifiers
    def repr(self): String = "<class " + name + ">"
}
