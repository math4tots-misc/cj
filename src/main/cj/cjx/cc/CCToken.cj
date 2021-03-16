package cjx.cc

class CCToken {
    static val tEOF = 201
    static val tINT = 202

    static val kwINT = 301

    static val keywordTypes: List[Int] = static_field_values!(Self, "kw[A-Z]+")

    static val typeNameMap: Map[Int, String] = Map(
        static_field_name_value_pairs!(Self, "(kw|t)[A-Z]+").map(p -> (p.f1, p.f0)))

    val type : Int
    val text : String
    val line : Int
    val column : Int

    def repr(self): String = (
        "CCToken(" + typeRepr(type) + ", " + text.repr() + ", " + line + ", " + column + ")")

    def keywordString(type: Int): String = {
        val str = typeRepr(type)
        Assert.withMessage(str.startsWith("kw"), str)
        str["kw".size():].lower()
    }

    def typeRepr(type: Int): String {
        if val name = typeNameMap.getOrNull(type) {
            name
        } else if type == '\n' or type >= 32 and type <= 127 {
            type.toChar().repr()
        } else {
            "Unknown(" + type + ")"
        }
    }
}
