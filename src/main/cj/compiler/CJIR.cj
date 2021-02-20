package compiler

import compiler.CJItemKind
import compiler.CJModifier
import compiler.CJMark

class CJIR {
    trait ItemDef: Repr {
        def __get_mark(self): CJMark
        def __get_comment(self): String?
        def __get_modifiers(self): List[CJModifier]
        def __get_kind(self): CJItemKind
        def __get_name(self): String
        def __get_typeParameters(self): List[TypeParameter]
        def __get_traits(self): List[Trait]
        def __get_methods(self): List[Method]
        def toString(self): String = name
        def repr(self): String = "(" + kind + " " + name + ")"
        def addTypeParameter(self, typeParameter: TypeParameter) {
            typeParameters.add(typeParameter)
        }
    }
    union ItemDef_: ItemDef {
        case class_(ClassDef)
        case union_(UnionDef)
        case trait_(TraitDef)
        def __get_mark(self): CJMark = when self {
            case class_(i) = i.mark
            case union_(i) = i.mark
            case trait_(i) = i.mark
        }
        def __get_comment(self): String? = when self {
            case class_(i) = i.comment
            case union_(i) = i.comment
            case trait_(i) = i.comment
        }
        def __get_modifiers(self): List[CJModifier] = when self {
            case class_(i) = i.modifiers
            case union_(i) = i.modifiers
            case trait_(i) = i.modifiers
        }
        def __get_kind(self): CJItemKind = when self {
            case class_(i) = CJItemKind.class_
            case union_(i) = CJItemKind.union_
            case trait_(i) = CJItemKind.trait_
        }
        def __get_name(self): String = when self {
            case class_(i) = i.name
            case union_(i) = i.name
            case trait_(i) = i.name
        }
        def __get_typeParameters(self): List[TypeParameter] = when self {
            case class_(i) = i.typeParameters
            case union_(i) = i.typeParameters
            case trait_(i) = i.typeParameters
        }
        def __get_traits(self): List[Trait] = when self {
            case class_(i) = i.traits
            case union_(i) = i.traits
            case trait_(i) = i.traits
        }
        def __get_methods(self): List[Method] = when self {
            case class_(i) = i.methods
            case union_(i) = i.methods
            case trait_(i) = i.methods
        }
    }

    trait ClassOrUnionDef: ItemDef {}
    union ClassOrUnionDef_ {
        case class_(ClassDef)
        case union_(UnionDef)
    }

    class ClassDef: ClassOrUnionDef {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traits: List[Trait] = []
        val fields: List[Field] = []
        val methods: List[Method] = []
        def __get_kind(self): CJItemKind = CJItemKind.class_
    }

    class UnionDef: ClassOrUnionDef {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traits: List[Trait] = []
        val methods: List[Method] = []
        def __get_kind(self): CJItemKind = CJItemKind.union_
    }

    class TraitDef: ItemDef {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traits: List[Trait] = []
        val methods: List[Method] = []
        def __get_kind(self): CJItemKind = CJItemKind.trait_
    }

    union Type {
        case reified(ReifiedType)
        case variable(TypeParameter)
    }

    class ReifiedType {
        val defn: ClassOrUnionDef
        val args: List[Type]
    }

    class Trait {
        val defn: TraitDef
        val args: List[Type]
    }

    class Field {
    }

    class Method {
    }

    class TypeParameter {
        val mark: CJMark
        val itemLevel: Bool
        val name: String
        val traits: List[Trait] = []
    }
}
