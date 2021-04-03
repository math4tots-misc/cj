package compiler

import cj.BigInt
import cjx.parser.MError
import compiler.CJItemKind
import compiler.CJModifier
import cjx.parser.Mark

class CJIR {
    trait ItemDef: Repr {
        def __get_mark(self): Mark
        def __get_comment(self): String?
        def __get_modifiers(self): List[CJModifier]
        def __get_kind(self): CJItemKind
        def __get_name(self): String
        def __get_typeParameters(self): List[TypeParameter]
        def __get_traitDeclarations(self): List[TraitDeclaration]
        def __get_methods(self): List[Method]
        def __get_methodMap(self): Map[String, Method]
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
        def isTrait(self): Bool = kind is CJItemKind.trait_
        def getSelfType(self, args: List[Type]): Type
        def getBinding(self, args: List[Type]): Binding {
            getBindingWithSelfType(getSelfType(args), args)
        }
        def getBindingWithSelfType(self, selfType: Type, args: List[Type]): Binding {
            Assert.equal(typeParameters.size(), args.size())
            val map: Map[String, Type] = MapOf()
            for i = 0; i < args.size(); i++ {
                map[typeParameters[i].name] = args[i]
            }
            Binding(selfType, map)
        }

        ## Gets the Method directly declared in this item
        def getMethodOrNull(self, shortName: String): Method? {
            if shortName not in methodMap {
                if val method = _getMethodOrNullNoCache(shortName) {
                    methodMap[shortName] = method
                }
            }
            methodMap.getOrNull(shortName)
        }

        def _getMethodOrNullNoCache(self, shortName: String): Method? {
            for method in methods {
                if method.name == shortName {
                    return null(method)
                }
            }
            null
        }
    }
    @implicit(ClassOrUnionDef_, _classOrUnion)
    @implicit(ClassDef, class_)
    @implicit(UnionDef, union_)
    @implicit(TraitDef, trait_)
    union ItemDef_: ItemDef {
        case class_(ClassDef)
        case union_(UnionDef)
        case trait_(TraitDef)
        def _classOrUnion(cu: ClassOrUnionDef): Self = when cu { else(defn) = defn }
        def __get_mark(self): Mark = when self { else(i) = i.mark }
        def __get_comment(self): String? = when self { else(i) = i.comment }
        def __get_modifiers(self): List[CJModifier] = when self { else(i) = i.modifiers }
        def __get_kind(self): CJItemKind = when self { else(i) = i.kind }
        def __get_name(self): String = when self { else(i) = i.name }
        def __get_typeParameters(self): List[TypeParameter] = when self {
            else(i) = i.typeParameters
        }
        def __get_traitDeclarations(self): List[TraitDeclaration] = when self {
            else(i) = i.traitDeclarations
        }
        def __get_methods(self): List[Method] = when self { else(i) = i.methods }
        def __get_methodMap(self): Map[String, Method] = when self { else(i) = i.methodMap }
        def getSelfType(self, args: List[Type]): Type = when self { else(i) = i.getSelfType(args) }
    }

    trait ClassOrUnionDef: ItemDef {}
    @implicit(ClassDef, class_)
    @implicit(UnionDef, union_)
    union ClassOrUnionDef_ : ClassOrUnionDef {
        case class_(ClassDef)
        case union_(UnionDef)
        def __get_mark(self): Mark = when self { else(i) = i.mark }
        def __get_comment(self): String? = when self { else(i) = i.comment }
        def __get_modifiers(self): List[CJModifier] = when self { else(i) = i.modifiers }
        def __get_kind(self): CJItemKind = when self { else(i) = i.kind }
        def __get_name(self): String = when self { else(i) = i.name }
        def __get_typeParameters(self): List[TypeParameter] = when self {
            else(i) = i.typeParameters
        }
        def __get_traitDeclarations(self): List[TraitDeclaration] = when self {
            else(i) = i.traitDeclarations
        }
        def __get_methods(self): List[Method] = when self { else(i) = i.methods }
        def __get_methodMap(self): Map[String, Method] = when self { else(i) = i.methodMap }
        def getSelfType(self, args: List[Type]): Type = when self { else(i) = i.getSelfType(args) }
    }

    class ClassDef: ClassOrUnionDef {
        val mark: Mark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traitDeclarations: List[TraitDeclaration] = []
        val fields: List[Field] = []
        val methods: List[Method] = []
        val methodMap: Map[String, Method] = MapOf()
        def __get_kind(self): CJItemKind = CJItemKind.class_
        def addField(self, field: Field) {
            fields.add(field)
        }
        def getSelfType(self, args: List[Type]): Type = ReifiedType(self, args)
    }

    class UnionDef: ClassOrUnionDef {
        val mark: Mark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traitDeclarations: List[TraitDeclaration] = []
        val cases: List[Case] = []
        val methods: List[Method] = []
        val methodMap: Map[String, Method] = MapOf()
        def __get_kind(self): CJItemKind = CJItemKind.union_
        def getSelfType(self, args: List[Type]): Type = ReifiedType(self, args)
    }

    class TraitDef: ItemDef {
        val mark: Mark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val typeParameters: List[TypeParameter] = []
        val traitDeclarations: List[TraitDeclaration] = []
        val methods: List[Method] = []
        val methodMap: Map[String, Method] = MapOf()
        def __get_kind(self): CJItemKind = CJItemKind.trait_
        def getSelfType(self, args: List[Type]): Type = SelfType(Trait(self, args))
    }

    class TraitDeclaration {
        val mark: Mark
        val trait_: Trait
        val conditions: List[TypeCondition]
    }

    class TypeCondition {
        val mark: Mark
        val variableName: String
        val traits: List[Trait]
        def isSatisfied(self, mark: Mark, binding: Binding): Bool {
            if val variableType = binding.map.getOrNull(variableName) {
                traits.all(trait_ -> variableType.implementsTrait(mark, trait_))
            } else { throw MError(variableName + " not found in binding", [mark]) }
        }
    }

    class TypeVar: Eq, Type {
        val decl: TypeParameter
        val additionalTraits: List[Trait] = [] # e.g. from conditions on methods
        def __get_mark(self): Mark = decl.mark
        def __get_name(self): String = decl.name
        def getTraits(self, mark: Mark): List[Trait] = decl.traits + additionalTraits
        def findTraitByName(self, mark: Mark, traitName: String): Trait? {
            CJIR._findTraitByName(getTraits(mark), mark, traitName)
        }
        def __eq(self, other: Self): Bool = name == other.name
    }

    class Binding {
        val selfType: Type
        val map: Map[String, Type]
    }

    trait Type {
    }

    @implicit(SelfType, self_)
    @implicit(ReifiedType, reified)
    @implicit(TypeVar, variable)
    union Type_: Repr, Eq, Type {
        case self_(SelfType)
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
        def __eq(self, other: Self): Bool = tag!(self) is tag!(other) and when self {
            case self_(t) = true
            case reified(rt) = rt == get!(other, reified, 0)
            case variable(tvar) = tvar == get!(other, variable, 0)
        }
        def applyBinding(self, mark: Mark, binding: Binding): Self {
            when self {
                case self_(..) = binding.selfType
                case reified(rtype) = Type.reified(rtype.applyBinding(mark, binding))
                case variable(tv) = if val t = binding.map.getOrNull(tv.name) { t } else {
                    throw MError(tv.name + " not found in binding", [mark])
                }
            }
        }
        def findTraitByName(self, mark: Mark, traitName: String): Trait? {
            when self {
                case self_(stype) = stype.selfTrait.findTraitByName(mark, traitName)
                else(t) = t.findTraitByName(mark, traitName)
            }
        }
        def implementsTrait(self, mark: Mark, trait_: Trait): Bool {
            if val implTrait = findTraitByName(mark, trait_.defn.name) {
                implTrait == trait_
            } else { false }
        }
    }

    trait ReifiedTypeOrTrait: Repr {
        def __get_item(self): ItemDef
        def applyBinding(self, mark: Mark, binding: Binding): Self
        def _getBinding(self): Binding
        def getTraits(self, mark: Mark): List[Trait]
        def findTraitByName(self, mark: Mark, traitName: String): Trait?
    }

    union ReifiedTypeOrTrait_: ReifiedTypeOrTrait {
        case reified(ReifiedType)
        case trait_(Trait)
        def applyBinding(self, mark: Mark, binding: Binding): Self = when self {
            case reified(t) = reified(t.applyBinding(mark, binding))
            case trait_(t) = trait_(t.applyBinding(mark, binding))
        }
        def _getBinding(self): Binding = when self { else(t) = t._getBinding() }
        def __get_item(self): ItemDef = when self { else(t) = t.item }
        def getTraits(self, mark: Mark): List[Trait] = when self { else(t) = t.getTraits(mark) }
        def findTraitByName(self, mark: Mark, traitName: String): Trait? = when self {
            else(t) = t.findTraitByName(mark, traitName)
        }
        def repr(self): String = when self { else(t) = t.repr() }
        def toString(self): String = when self { else(t) = t.toString() }
    }

    @derive(repr)
    class ReifiedType: Eq, ReifiedTypeOrTrait, Type {
        val defn: ClassOrUnionDef
        val args: List[Type]
        def __get_item(self): ItemDef = defn
        def toString(self): String = if args { defn.name + args } else { defn.name }
        def __eq(self, other: Self): Bool = defn.name == other.defn.name and args == other.args
        def applyBinding(self, mark: Mark, binding: Binding): Self {
            ReifiedType(defn, args.map(arg -> arg.applyBinding(mark, binding)))
        }
        def _getBinding(self): Binding {
            val map: Map[String, Type] = Map([])
            for i = 0; i < args.size(); i++ {
                map[defn.typeParameters[i].name] = args[i]
            }
            Binding(Type.reified(self), map)
        }
        def getTraits(self, mark: Mark): List[Trait] {
            val binding = _getBinding()
            CJIR._getTraits(mark, binding, defn.traitDeclarations)
        }
        def findTraitByName(self, mark: Mark, traitName: String): Trait? {
            CJIR._findTraitByName(getTraits(mark), mark, traitName)
        }
    }

    class SelfType: Type {
        val selfTrait: Trait
    }

    @derive(repr)
    class Trait: Eq, ReifiedTypeOrTrait {
        val defn: TraitDef
        val args: List[Type]
        def __get_item(self): ItemDef = defn
        def toString(self): String = if args { defn.name + args } else { defn.name }
        def __eq(self, other: Self): Bool = defn is other.defn and args == other.args
        def applyBinding(self, mark: Mark, binding: Binding): Trait {
            Trait(defn, args.map(arg -> arg.applyBinding(mark, binding)))
        }
        def _getBinding(self): Binding {
            val map: Map[String, Type] = Map([])
            for i = 0; i < args.size(); i++ {
                map[defn.typeParameters[i].name] = args[i]
            }
            Binding(SelfType(self), map)
        }
        def getTraits(self, mark: Mark): List[Trait] {
            val binding = _getBinding()
            CJIR._getTraits(mark, binding, defn.traitDeclarations)
        }
        def findTraitByName(self, mark: Mark, traitName: String): Trait? {
            CJIR._findTraitByName([self], mark, traitName)
        }
    }

    def _getTraits(mark: Mark, binding: Binding, decls: List[TraitDeclaration]): List[Trait] {
        val traits = List[Trait].empty()
        for traitDecl in decls {
            if traitDecl.conditions.all(c -> c.isSatisfied(mark, binding)) {
                traits.add(traitDecl.trait_.applyBinding(mark, binding))
            }
        }
        traits
    }

    def _findTraitByName(rootTraits: List[Trait], mark: Mark, traitName: String): Trait? {
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
        val mark: Mark
        val comment: String?
        val modifiers: List[CJModifier]
        val name: String
        val types: List[Type]
    }

    class Field {
        val mark: Mark
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
        val mark: Mark
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
        val mark: Mark
        val itemLevel: Bool
        val name: String
        val traits: List[Trait] = []
        def addTrait(self, trait_: Trait) {
            traits.add(trait_)
        }
        def toString(self): String = name
    }

    class Local {
        val mark: Mark
        val mutable: Bool
        val name: String
        val type: Type
    }

    class Expr {
        val mark: Mark
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
        case call(Type, List[Expr])
    }
}
