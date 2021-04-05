package compiler

import compiler.CJModifier
import cjx.parser.Mark

## CJ low-level IR
class CJLR {

    class Program {
        val typeMap: Map[String, Type] = MapOf()

        def addType(self, type: Type) {
            typeMap[type.name] = type
        }
    }

    class Type {
        val mark: Mark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val methodMap: Map[String, Method] = MapOf()
    }

    class Method {
        val mark: Mark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val parameters: List[Var]
        val returnType: Type
        var body: Expr? = null
    }

    class Var {
        val mark: Mark
        val name: String
        val type: Type
        val init: Expr?
    }

    class Expr {
        val mark: Mark
        val type: Type
        val data: ExprData
    }

    union ExprData {
        case int(Int)
    }
}
