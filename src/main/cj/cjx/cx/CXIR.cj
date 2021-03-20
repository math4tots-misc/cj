package cjx.cx

import cjx.parser.Mark

class CXIR {

    trait Item: Repr {
        def __get_mark(self): Mark
        def __get_name(self): String
        def __get_traits(self): List[Trait]
        def __get_methods(self): List[Method]
        def repr(self): String = name
    }

    class Type : Item {
        val mark: Mark
        val name: String
        val traits: List[Trait]
        val methods: List[Method]
    }

    class Trait : Item {
        val mark: Mark
        val name: String
        val traits: List[Trait]
        val methods: List[Method]
    }

    class Var {
        val mark: Mark
        val mutable: Bool
        val name: String
        val type: Type
        val init: Expr?
    }

    class Method {
        val mark: Mark
        val name: String
        val parameters: List[Var]
        val returnType: Type
        val body: Expr?
    }

    union Expr: Expr.Trait {
        trait Trait {
            def __get_mark(self): Mark
        }

        class IntLiteral : Trait {
            val mark: Mark
            val value: Int
        }

        class StringLiteral : Trait {
            val mark: Mark
            val value: String
        }

        class GetVar: Trait {
            val mark: Mark
            val variable: Var
        }

        case int(IntLiteral)
        case string(StringLiteral)
        case getvar(GetVar)

        def __get_mark(self): Mark = when self { else(e) = e.mark }
    }
}
