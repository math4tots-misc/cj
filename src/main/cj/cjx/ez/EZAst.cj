package cjx.ez

import cjx.ez.EZMark

class EZAst {

    @derive(new)
    class File {
        val mark: EZMark
        val packageName: String
        val imports: List[Import]
        val items: List[Item]
    }

    @derive(new)
    class Import {
        val mark: EZMark
        val qualifiedName: String
        val alias: String
    }

    union Item {
        case class_(Class)
    }

    @derive(new)
    class Class {
        val mark: EZMark
        val modifiers: List[String]
        val shortName: String
        val members: List[Member]
    }

    union Member {
        case field(Field)
        case method(Method)
    }

    @derive(new)
    class Field {
        val mark: EZMark
        val modifiers: List[String]
        val name: String
        val type: Type
        val init: Nullable[Expr]
    }

    @derive(new)
    class Method {
        val mark: EZMark
        val modifiers: List[String]
        val name: String
        val parameters: List[Local]
        val returnType: Type
        val body: Nullable[Expr]
    }

    @derive(new)
    class Local {
        val mark: EZMark
        val name: String
        val type: Nullable[Type]
    }

    @derive(new)
    class Type {
        val mark: EZMark
        val name: String
        val args: List[Type]
    }

    @derive(new)
    class Expr {
        val mark: EZMark
        val data: ExprData
    }

    union ExprData {
        case unit
    }
}
