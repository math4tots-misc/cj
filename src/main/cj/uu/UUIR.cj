package uu

import cjx.parser.Mark
import uu.UUAst.Item.Kind as IKind
import uu.UUAst.Modifier

class UUIR {
    class Module {
        val typeMap: Map[String, Type] = MapOf()
    }

    class Type {
        val mark: Mark
        val comment: String?
        val name: String
        val memberMap: Map[String, Member] = MapOf()
    }

    union Member {
        case method(Method)
    }

    class Method {
        val mark: Mark
        val name: String
        val returnType: Type
        val parameters: List[Var] = []
        var variadic = false
        var body: Expr? = null
    }

    class Var {
        val mark: Mark
        val mutable: Bool
        val name: String
        val type: Type
    }

    class Expr {
        union Kind {
            case int
        }
        val mark: Mark
        val kind: Kind
        var intValue: Int = ?
    }
}
