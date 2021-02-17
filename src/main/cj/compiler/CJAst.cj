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
        val name: String
        val typeParameters: List[TypeParameter]
        val traitDeclarations: List[TraitDeclaration]
        val members: List[Member]
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
        val type: Type
        val init: Expr?
    }

    class Method {
        val mark: CJMark
        val comment: String?
        val annotations: List[Annotation]
        val modifiers: List[CJModifier]
        val conditions: List[TypeCondition]
        val name: String
        val parameters: List[Local]
        val returnType: Type
        val body: Expr?
    }

    class Trait {
        val mark: CJMark
        val name: String
        val args: List[Type]
    }

    class Type {
        val mark: CJMark
        val name: String
        val args: List[Type]
    }

    class Expr {
        val mark: CJMark
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
        case block(List[Expr])
        case call(Nullable[Type], String, List[Type], List[Expr])
        case callname(String, List[Type], List[Expr])
        case decl(DeclTarget, Nullable[Type], Expr)
        case getvar(String)
        case setvar(String, Expr)
        case augvar(String, AugKind, Expr)
        case logicalNot(Expr)
        case logicalAnd(Expr, Expr)
        case logicalOr(Expr, Expr)
        case is_(Expr, Expr)
        case null_(Nullable[Type], Expr?)
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

    class WhenCase {
        val mark: CJMark
        val name: String
        val decls: List[Local]
        val dotdot: Bool
        val body: Expr
    }

    class SwitchCase {
        val valexprs: List[Expr]
        val body: Expr
    }

    class Catch {
        val target: DeclTarget
        val type: Type
        val body: Expr
    }

    class Local {
        val mark: CJMark
        val mutable: Bool
        val name: String
        val type: Type?
    }

    union AugKind {
        case add
        case subtract
        case multiply
        case remainder
    }

    class DeclTarget {
        val mark: CJMark
        val data: DeclTargetData
    }

    union DeclTargetData {
        case name(Local)
        case tuple(List[DeclTarget])
    }
}
