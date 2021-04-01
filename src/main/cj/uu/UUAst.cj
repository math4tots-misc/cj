package uu

import cj.StringBuilder
import cjx.parser.Mark

class UUAst {

    class File {
        val mark: Mark
        val packageName: String
        val imports: List[Import]
        val item: Item
    }

    class Import {
        val mark: Mark
        val fullName: String
        val alias: String
    }

    class Item {
        union Kind: Hash {
            case class_
            case union_
            case trait_
            case interface_
            def __eq(self, other: Self): Bool = tag!(self) is tag!(other)
            def hash(self): Int = tag!(self)
        }
        val mark: Mark
        val comment: String?
        val annotations: List[Annotation]
        val modifiers: List[Modifier]
        val kind: Kind
        val shortName: String
        val members: List[Member]
        def getMethodOrNull(self, name: String): Method? {
            for member in members {
                when member {
                    case method(m) = if m.name == name { return null(m) }
                    else = ()
                }
            }
            null
        }
    }

    class Annotation {
        val mark: Mark
        val name: String
        val args: List[Annotation]
    }

    union Modifier: Hash {
        case native_
        case static_
        case public_
        case private_
        case async_
        case synthetic
        def __eq(self, other: Self): Bool = tag!(self) is tag!(other)
        def hash(self): Int = tag!(self)
    }

    @implicit(Item, item)
    @implicit(Method, method)
    union Member {
        case item(Item)
        case method(Method)
    }

    class Var {
        val mark: Mark
        val mutable: Bool
        val name: String
        val type: TypeExpr
    }

    class TypeExpr {
        val mark: Mark
        val name: String
        val args: List[TypeExpr]
    }

    class TraitExpr {
        val mark: Mark
        val name: String
        val args: List[TypeExpr]
    }

    class Method {
        val mark: Mark
        val comment: String?
        val annotations: List[Annotation]
        val modifiers: List[Modifier]
        val name: String
        val parameters: List[Var]
        val returnType: TypeExpr
        val body: Expr?
    }

    class Expr: Repr {
        union Kind: Repr {
            case int
            case block
            def repr(self): String = tag_name!(self)
        }
        val mark: Mark
        val kind: Kind
        var intValue: Int = ?
        var args: List[Expr] = ?
        def int(mark: Mark, value: Int): Expr {
            val ret = Expr(mark, Kind.int)
            ret.intValue = value
            ret
        }
        def block(mark: Mark, args: List[Expr]): Expr {
            val ret = Expr(mark, Kind.block)
            ret.args = args
            ret
        }
        def repr(self): String {
            val sb = StringBuilder()
            sb.str("{")
            sb.str("\"kind\":\"" + kind + "\"")
            if is_set!(self, intValue) { sb.str(",\"intValue:\":" + intValue) }
            if is_set!(self, args) { sb.str(",\"args:\":" + args) }
            sb.str("}")
            sb.toString()
        }
    }
}
