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
        def __get_traitDeclarations(self): List[TraitDeclaration]
        def __get_methods(self): List[Method]
        def toString(self): String = name
        def repr(self): String = "(" + kind + " " + name + ")"
        def addTypeParameter(self, typeParameter: TypeParameter) {
            typeParameters.add(typeParameter)
        }
        def addTraitDeclaration(self, traitDecl: TraitDeclaration) {
            traitDeclarations.add(traitDecl)
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
        def __get_traitDeclarations(self): List[TraitDeclaration] = when self {
            case class_(i) = i.traitDeclarations
            case union_(i) = i.traitDeclarations
            case trait_(i) = i.traitDeclarations
        }
        def __get_methods(self): List[Method] = when self {
            case class_(i) = i.methods
            case union_(i) = i.methods
            case trait_(i) = i.methods
        }
    }

    trait ClassOrUnionDef: ItemDef {}
    union ClassOrUnionDef_ : ClassOrUnionDef {
        case class_(ClassDef)
        case union_(UnionDef)
        def __get_mark(self): CJMark = when self {
            case class_(i) = i.mark
            case union_(i) = i.mark
        }
        def __get_comment(self): String? = when self {
            case class_(i) = i.comment
            case union_(i) = i.comment
        }
        def __get_modifiers(self): List[CJModifier] = when self {
            case class_(i) = i.modifiers
            case union_(i) = i.modifiers
        }
        def __get_kind(self): CJItemKind = when self {
            case class_(i) = CJItemKind.class_
            case union_(i) = CJItemKind.union_
        }
        def __get_name(self): String = when self {
            case class_(i) = i.name
            case union_(i) = i.name
        }
        def __get_typeParameters(self): List[TypeParameter] = when self {
            case class_(i) = i.typeParameters
            case union_(i) = i.typeParameters
        }
        def __get_traitDeclarations(self): List[TraitDeclaration] = when self {
            case class_(i) = i.traitDeclarations
            case union_(i) = i.traitDeclarations
        }
        def __get_methods(self): List[Method] = when self {
            case class_(i) = i.methods
            case union_(i) = i.methods
        }
    }

    class ClassDef: ClassOrUnionDef {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traitDeclarations: List[TraitDeclaration] = []
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
        val traitDeclarations: List[TraitDeclaration] = []
        val methods: List[Method] = []
        def __get_kind(self): CJItemKind = CJItemKind.union_
    }

    class TraitDef: ItemDef {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traitDeclarations: List[TraitDeclaration] = []
        val methods: List[Method] = []
        def __get_kind(self): CJItemKind = CJItemKind.trait_
    }

    class TraitDeclaration {
        val mark: CJMark
        val trait_: Trait
        val conditions: List[TypeCondition]
    }

    class TypeCondition {
        val mark: CJMark
        val variableName: String
        val traits: List[Trait]
    }

    class TypeVar {
        val decl: TypeParameter
        def __get_mark(self): CJMark = decl.mark
        def __get_name(self): String = decl.name
    }

    union Type: Repr, Eq {
        case reified(ReifiedType)
        case variable(TypeVar)
        def repr(self): String = when self {
            case reified(t) = t.toString()
            case variable(tp) = tp.name
        }
        def __eq(self, other: Self): Bool = repr() == other.repr()
    }

    @derive(repr)
    class ReifiedType: Eq {
        val defn: ClassOrUnionDef
        val args: List[Type]
        def toString(self): String = if args { defn.name + args } else { defn.name }
        def __eq(self, other: Self): Bool = toString() == other.toString()
    }

    @derive(repr)
    class Trait: Eq {
        val defn: TraitDef
        val args: List[Type]
        def toString(self): String = if args { defn.name + args } else { defn.name }
        def __eq(self, other: Self): Bool = toString() == other.toString()
    }

    class Field {
    }

    class Method {
    }

    class TypeParameter: ToString {
        val mark: CJMark
        val itemLevel: Bool
        val name: String
        val traits: List[Trait] = []
        def addTrait(self, trait_: Trait) {
            traits.add(trait_)
        }
        def toString(self): String = name
    }
}
