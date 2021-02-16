package cjx.ez

import cjx.ez.EZMark

class EZAst {

    class File {
        val mark: EZMark
        val packageName: String
        val imports: List[Import]
        val items: List[Item]
    }

    class Import {
        val mark: EZMark
        val qualifiedName: String
        val alias: String
    }

    union Item {
        case class_(Class)
    }

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

    class Field {
        val mark: EZMark
        val modifiers: List[String]
        val name: String
        val type: Type
        val init: Nullable[Expr]
    }

    class Method {
        val mark: EZMark
        val modifiers: List[String]
        val name: String
        val parameters: List[Local]
        val returnType: Type
        val body: Nullable[Expr]
    }

    class Local {
        val mark: EZMark
        val name: String
        val type: Nullable[Type]
    }

    class Type {
        val mark: EZMark
        val name: String
        val args: List[Type]
    }

    class Expr {
        val mark: EZMark
        val data: ExprData
    }

    union ExprData {
        case unit
    }
}
