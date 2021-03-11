package compiler

import cj.BigInt
import compiler.CJError
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
        def addMethod(self, method: Method) {
            methods.add(method)
        }
        def __get_native_(self): Bool = CJModifier.native_ in modifiers
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
        def addField(self, field: Field) {
            fields.add(field)
        }
    }

    class UnionDef: ClassOrUnionDef {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traitDeclarations: List[TraitDeclaration] = []
        val cases: List[Case] = []
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
        def isSatisfied(self, mark: CJMark, binding: Binding): Bool {
            if val variableType = binding.map.getOrNull(variableName) {
                traits.all(trait_ -> variableType.implementsTrait(mark, trait_))
            } else { throw CJError(variableName + " not found in binding", [mark]) }
        }
    }

    class TypeVar: Eq {
        val decl: TypeParameter
        val additionalTraits: List[Trait] = [] # e.g. from conditions on methods
        def __get_mark(self): CJMark = decl.mark
        def __get_name(self): String = decl.name
        def getTraits(self, mark: CJMark): List[Trait] = decl.traits + additionalTraits
        def findTraitByName(self, mark: CJMark, traitName: String): Trait? {
            CJIR._findTraitByName(getTraits(mark), mark, traitName)
        }
        def __eq(self, other: Self): Bool = name == other.name
    }

    class Binding {
        val selfType: Type
        val map: Map[String, Type]
    }

    union Type: Repr, Eq {
        case self_(Trait)
        case reified(ReifiedType)
        case variable(TypeVar)
        def repr(self): String = when self {
            case self_(t) = "Self"
            case reified(t) = t.toString()
            case variable(tv) = tv.name
        }
        def __get_name(self): String = when self {
            case self_(t) = "Self"
            case reified(t) = t.defn.name
            case variable(tv) = tv.name
        }
        def __eq(self, other: Self): Bool = when self {
            case self_(t) = when other { case self_(ot) = true; else = false }
            case reified(rt) = when other { case reified(ot) = rt == ot; else = false }
            case variable(tvar) = when other { case variable(ovar) = tvar == ovar; else = false }
        }
        def applyBinding(self, mark: CJMark, binding: Binding): Self {
            when self {
                case self_(trait_) = binding.selfType
                case reified(rtype) = Type.reified(rtype.applyBinding(mark, binding))
                case variable(tv) = if val t = binding.map.getOrNull(tv.name) { t } else {
                    throw CJError(tv.name + " not found in binding", [mark])
                }
            }
        }
        def findTraitByName(self, mark: CJMark, traitName: String): Trait? {
            when self {
                case self_(trait_) = trait_.findTraitByName(mark, traitName)
                case reified(rtype) = rtype.findTraitByName(mark, traitName)
                case variable(tvar) = tvar.findTraitByName(mark, traitName)
            }
        }
        def implementsTrait(self, mark: CJMark, trait_: Trait): Bool {
            if val implTrait = findTraitByName(mark, trait_.defn.name) {
                implTrait == trait_
            } else { false }
        }
    }

    trait ReifiedTypeOrTrait: Repr {
        def applyBinding(self, mark: CJMark, binding: Binding): Self
        def _getBinding(self): Binding
        def getTraits(self, mark: CJMark): List[Trait]
        def findTraitByName(self, mark: CJMark, traitName: String): Trait?
    }

    union ReifiedTypeOrTrait_: ReifiedTypeOrTrait {
        case reified(ReifiedType)
        case trait_(Trait)
        def applyBinding(self, mark: CJMark, binding: Binding): Self = when self {
            case reified(t) = reified(t.applyBinding(mark, binding))
            case trait_(t) = trait_(t.applyBinding(mark, binding))
        }
        def _getBinding(self): Binding = when self {
            case reified(t) = t._getBinding()
            case trait_(t) = t._getBinding()
        }
        def getTraits(self, mark: CJMark): List[Trait] = when self {
            case reified(t) = t.getTraits(mark)
            case trait_(t) = t.getTraits(mark)
        }
        def findTraitByName(self, mark: CJMark, traitName: String): Trait? = when self {
            case reified(t) = t.findTraitByName(mark, traitName)
            case trait_(t) = t.findTraitByName(mark, traitName)
        }
        def repr(self): String = when self {
            case reified(t) = t.repr()
            case trait_(t) = t.repr()
        }
        def toString(self): String = when self {
            case reified(t) = t.toString()
            case trait_(t) = t.toString()
        }
    }

    @derive(repr)
    class ReifiedType: Eq, ReifiedTypeOrTrait {
        val defn: ClassOrUnionDef
        val args: List[Type]
        def toString(self): String = if args { defn.name + args } else { defn.name }
        def __eq(self, other: Self): Bool = defn.name == other.defn.name and args == other.args
        def applyBinding(self, mark: CJMark, binding: Binding): Self {
            ReifiedType(defn, args.map(arg -> arg.applyBinding(mark, binding)))
        }
        def _getBinding(self): Binding {
            val map: Map[String, Type] = Map([])
            for i = 0; i < args.size(); i++ {
                map[defn.typeParameters[i].name] = args[i]
            }
            Binding(Type.reified(self), map)
        }
        def getTraits(self, mark: CJMark): List[Trait] {
            val binding = _getBinding()
            CJIR._getTraits(mark, binding, defn.traitDeclarations)
        }
        def findTraitByName(self, mark: CJMark, traitName: String): Trait? {
            CJIR._findTraitByName(getTraits(mark), mark, traitName)
        }
    }

    @derive(repr)
    class Trait: Eq, ReifiedTypeOrTrait {
        val defn: TraitDef
        val args: List[Type]
        def toString(self): String = if args { defn.name + args } else { defn.name }
        def __eq(self, other: Self): Bool = defn is other.defn and args == other.args
        def applyBinding(self, mark: CJMark, binding: Binding): Trait {
            Trait(defn, args.map(arg -> arg.applyBinding(mark, binding)))
        }
        def _getBinding(self): Binding {
            val map: Map[String, Type] = Map([])
            for i = 0; i < args.size(); i++ {
                map[defn.typeParameters[i].name] = args[i]
            }
            Binding(Type.self_(self), map)
        }
        def getTraits(self, mark: CJMark): List[Trait] {
            val binding = _getBinding()
            CJIR._getTraits(mark, binding, defn.traitDeclarations)
        }
        def findTraitByName(self, mark: CJMark, traitName: String): Trait? {
            CJIR._findTraitByName([self], mark, traitName)
        }
    }

    def _getTraits(mark: CJMark, binding: Binding, decls: List[TraitDeclaration]): List[Trait] {
        val traits = List[Trait].empty()
        for traitDecl in decls {
            if traitDecl.conditions.all(c -> c.isSatisfied(mark, binding)) {
                traits.add(traitDecl.trait_.applyBinding(mark, binding))
            }
        }
        traits
    }

    def _findTraitByName(rootTraits: List[Trait], mark: CJMark, traitName: String): Trait? {
        for rootTrait in rootTraits {
            if rootTrait.defn.name == traitName {
                return null(rootTrait)
            }
        }
        val stack = rootTraits.reversed()
        val seen = stack.map(t -> t.defn.name).toSet()
        while stack {
            val trait_ = stack.pop()
            val subtraits = trait_.getTraits(mark).filter(t -> t.defn.name not in seen)
            for subtrait in subtraits {
                if subtrait.defn.name == traitName {
                    return null(subtrait)
                }
            }
            subtraits.reverse()
            stack.addAll(subtraits)
            seen.addAll(subtraits.map(t -> t.defn.name))
        }
        null
    }

    class Case {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val types: List[Type]
    }

    class Field {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val mutable: Bool
        val name: String
        val type: Type
        var init: Expr? = null
        var lateinit = false
        def __get_static_(self): Bool = CJModifier.static_ in modifiers
    }

    class Method {
        val mark: CJMark
        val comment: String?
        val modifiers: List[CJModifier]
        val conditions: List[TypeCondition]
        val name: String
        val typeParameters: List[TypeParameter]
        val parameters: List[Local]
        val returnType: Type
        val hasImpl: Bool
        var body: Expr? = null
        var variadic = false
        var test = false
        def __get_synthetic(self): Bool = CJModifier.synthetic in modifiers
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

    class Local {
        val mark: CJMark
        val mutable: Bool
        val name: String
        val type: Type
    }

    class Expr {
        val mark: CJMark
        val type: Type
        val data: ExprData
    }

    union ExprData {
        case unit
        case bool(Bool)
        case char(Char)
        case int(Int)
        case double(Double)
        case string(String)
        case bigint(BigInt)
        case null_(Expr?)
    }
}
