package compiler

import compiler.CJItemKind
import compiler.CJModifier
import compiler.CJMark

class CJIR {
    trait Item {
        def __get_mark(self): CJMark
        def __get_comment(self): String?
        def __get_modifiers(self): List[CJModifier]
        def __get_name(self): String
        def __get_typeParameters(self): List[TypeParameter]
        def __get_traits(self): List[Trait]
        def __get_methods(self): List[Method]
    }
    union Item_ {
        case class_(Class)
        case union_(Union)
        case trait_(Trait)
        def __get_mark(self): CJMark = when self {
            case class_(i) = i.mark
            case union_(i) = i.mark
            case trait_(i) = i.mark
        }
        def __get_name(self): String = when self {
            case class_(i) = i.name
            case union_(i) = i.name
            case trait_(i) = i.name
        }
        def __get_kind(self): CJItemKind = when self {
            case class_(i) = CJItemKind.class_
            case union_(i) = CJItemKind.union_
            case trait_(i) = CJItemKind.trait_
        }
    }

    trait ClassOrUnion: Item {}
    union ClassOrUnion_ {
        case class_(Class)
        case union_(Union)
    }

    class Class: ClassOrUnion {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traits: List[Trait] = []
        val fields: List[Field] = []
        val methods: List[Method] = []
    }

    class Union: ClassOrUnion {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traits: List[Trait] = []
        val methods: List[Method] = []
    }

    class Trait: Item {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traits: List[Trait] = []
        val methods: List[Method] = []
    }

    class Field {
    }

    class Method {
    }

    class TypeParameter {
    }
}
