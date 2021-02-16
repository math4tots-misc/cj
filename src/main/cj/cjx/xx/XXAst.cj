package cjx.xx

import cjx.xx.XXMark

class XXAst {

    class File {
        val mark: XXMark
        val packageName: String
        val imports: List[Import]
        val items: List[Item]
    }

    class Import {
        val mark: XXMark
        val fullName: String
        val alias: String
    }

    @derive(repr)
    union ItemKind: Eq {
        case class_
        case union_
        case trait_
        case interface_
        def __eq(self, other: Self): Bool = repr() == other.repr()
    }

    class Item {
        val mark: XXMark
        val kind: ItemKind
        val modifiers: List[String]
        val shortName: String
        val templateParameters: List[TemplateParameter]
        val nestedItems: List[Item]
        val itemBody: ItemBody
    }

    class TemplateParameter {
        val mark: XXMark
        val name: String
    }

    union ItemBody {
        case if_(Expr, ItemBody)
        case block(List[ItemBody])
        case field(Field)
        case method(Method)
    }

    class Field {
        val mark: XXMark
        val modifiers: List[String]
        val name: String
        val type: Nullable[Type]
        val init: Nullable[Expr]
    }

    class Method {
        val mark: XXMark
        val modifiers: List[String]
        val name: String
        val templateParameters: List[TemplateParameter]
        val parameters: List[Local]
        val returnType: Type
        val body: Nullable[Expr]
    }

    class Local {
        val mark: XXMark
        val name: String
        val type: Nullable[Type]
    }

    class Type {
        val mark: XXMark
        val name: String
        val args: List[Expr]
    }

    class Expr {
        val mark: XXMark
        val data: ExprData
    }

    union ExprData {
        case type(Type)
        case bool(Bool)
        case int(Int)
        case string(String)
        case block(List[Expr])
        case callname(String, List[Expr])
        case callmethod(Expr, String, List[Expr])
    }
}
