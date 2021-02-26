package compiler

import compiler.CJItemKind
import compiler.CJModifier
import cj.BigInt
import compiler.CJMark

class CJAst {

    class File {
        val mark: CJMark
        val packageName: String
        val imports: List[Import]
        val item: Item
    }

    class Import {
        val mark: CJMark
        val fullName: String
        val alias: String
    }

    class Item {
        val mark: CJMark
        val comment: String?
        val annotations: List[Annotation]
        val modifiers: List[CJModifier]
        val kind: CJItemKind
        val shortName: String
        val typeParameters: List[TypeParameter]
        val traitDeclarations: List[TraitDeclaration]
        val members: List[Member]
        def __get_native_(self): Bool = CJModifier.native_ in modifiers
        def __get_nonStaticFields(self): List[Field] {
            val fields = List[Field]()
            for member in members {
                when member {
                    case field(field) = fields.add(field)
                    else = ()
                }
            }
            fields
        }
        def __get_cases(self): List[Case] {
            val cases = List[Case]()
            for member in members {
                when member {
                    case case_(case_) = cases.add(case_)
                    else = ()
                }
            }
            cases
        }
    }

    class TypeParameter {
        val mark: CJMark
        val itemLevel: Bool
        val annotations: List[Annotation]
        val name: String
        val traits: List[Trait]
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

    class Annotation {
        val mark: CJMark
        val name: String
        val args: List[Annotation]
    }

    union Member {
        case item(Item)
        case case_(Case)
        case field(Field)
        case method(Method)
    }

    class Case {
        val mark: CJMark
        val comment: String?
        val annotations: List[Annotation]
        val modifiers: List[CJModifier]
        val name: String
        val types: List[Type]
    }

    class Field {
        val mark: CJMark
        val comment: String?
        val annotations: List[Annotation]
        val modifiers: List[CJModifier]
        val mutable: Bool
        val name: String
        val type: Type?
        val init: Expr?
        def __get_static_(self): Bool = CJModifier.static_ in modifiers
        def __get_lateinit(self): Bool {
            for annotation in annotations {
                switch annotation.name {
                    case "lateinit" = return true
                    else = ()
                }
            }
            false
        }
    }

    class Method {
        val mark: CJMark
        val comment: String?
        val annotations: List[Annotation]
        val modifiers: List[CJModifier]
        val conditions: List[TypeCondition]
        val name: String
        val typeParameters: List[TypeParameter]
        val parameters: List[Local]
        val returnType: Type?
        val body: Expr?
    }

    trait TraitOrType: Repr {
        def __get_name(self): String
        def __get_args(self): List[Type]
        def repr(self): String = {
            if args {
                name + "[" + ", ".join(args.map(a -> a.repr())) + "]"
            } else { name }
        }
    }

    class Trait: TraitOrType {
        val mark: CJMark
        val name: String
        val args: List[Type]
    }

    class Type: TraitOrType {
        val mark: CJMark
        val name: String
        val args: List[Type]
    }

    class Expr: Repr {
        val mark: CJMark
        val data: ExprData
        def repr(self): String = data.repr()
    }

    @derive(repr)
    union ExprData {
        case unit
        case bool(Bool)
        case char(Char)
        case int(Int)
        case double(Double)
        case string(String)
        case bigint(BigInt)
        case block(List[Expr])
        case call(Type?, String, List[Type], List[Expr])
        case callname(String, List[Type], List[Expr])
        case decl(DeclTarget, Type?, Expr)
        case getvar(String)
        case setvar(String, Expr)
        case augvar(String, AugKind, Expr)
        case getfield(Expr, String)
        case setfield(Expr, String, Expr)
        case augfield(Expr, String, AugKind, Expr)
        case getstatic(Type, String)
        case setstatic(Type, String, Expr)
        case augstatic(Type, String, AugKind, Expr)
        case logicalNot(Expr)
        case logicalAnd(Expr, Expr)
        case logicalOr(Expr, Expr)
        case is_(Expr, Expr)
        case null_(Type?, Expr?)
        case list(List[Expr])
        case tuple(List[Expr])
        case if_(Expr, Expr, Expr?)
        case ifNull(DeclTarget, Expr, Expr, Expr?)
        case while_(Expr, Expr)
        case for_(DeclTarget, Expr, Expr)
        case when_(Expr, List[WhenCase], Expr?)
        case switch_(Expr, List[SwitchCase], Expr?)
        case lambda(Bool, List[Local], Expr)
        case return_(Expr)
        case await_(Expr)
        case throw_(Expr)
        case try_(Expr, List[Catch], Expr?)
    }

    class WhenCase: Repr {
        val patterns: List[Tuple[CJMark, String, List[Local], Bool]]
        val body: Expr
        def repr(self): String {
            "CaseWhen(" + ", ".join(patterns.map(t ->
                "[" + t.get1() + ", " + t.get2() + ", " + t.get3() + "]")) + ", " + body + ")"
        }
    }

    @derive(repr)
    class SwitchCase: Repr {
        val valexprs: List[Expr]
        val body: Expr
    }

    @derive(repr)
    class Catch: Repr {
        val target: DeclTarget
        val type: Type
        val body: Expr
    }

    class Local: Repr {
        val mark: CJMark
        val mutable: Bool
        val name: String
        val type: Type?
        def repr(self): String {
            val lead = if mutable { "var " } else { "" }
            val tail = if val t = type { ": " + type } else { "" }
            lead + name + tail
        }
    }

    @derive(repr)
    union AugKind {
        case add
        case subtract
        case multiply
        case remainder
    }

    class DeclTarget: Repr {
        val mark: CJMark
        val data: DeclTargetData
        def repr(self): String = data.repr()
    }

    union DeclTargetData: Repr {
        case name(Local)
        case tuple(List[DeclTarget])
        def repr(self): String = when self {
            case name(local) = local.repr()
            case tuple(decls) = "(" + decls.map(d -> d.repr()) + ")"
        }
    }
}
