package compiler.solver

import compiler.CJError
import compiler.CJMark
import compiler.CJScope
import compiler.CJAst
import compiler.CJIR
import compiler.CJIR.Type
import compiler.CJIR.Trait
import compiler.CJIR.ReifiedType

trait CJTypeSolverMixin {

    def getItemDefOrNull(self, fullName: String): CJIR.ItemDef?

    def solveTrait(self, scope: CJScope, expr: CJAst.Trait): Trait {
        val args = expr.args.map(arg -> solveType(scope, arg))
        solveTraitEx(scope, expr.mark, expr.name, args)
    }

    def solveTraitEx(
            self, scope: CJScope, mark: CJMark, shortName: String, args: List[Type]): Trait {
        val dotIndex = shortName.indexOf(".")
        val outerShortName = if dotIndex == -1 { shortName } else { shortName[:dotIndex] }
        if val data = scope.getOrNull(outerShortName) {
            when data {
                case fullName(prefix) {
                    val fullName = if dotIndex == -1 { prefix } else {
                        prefix + "." + shortName[dotIndex + 1:]
                    }
                    getReifiedTrait(mark, fullName, args)
                }
                case type(type) {
                    throw CJError("Expected trait but got type", [mark])
                }
            }
        } else {
            throw CJError("Name " + outerShortName + " not found in this scope", [mark])
        }
    }

    def solveType(self, scope: CJScope, expr: CJAst.Type): Type {
        val args = expr.args.map(arg -> solveType(scope, arg))
        solveTypeEx(scope, expr.mark, expr.name, args)
    }

    def solveTypeEx(
            self, scope: CJScope, mark: CJMark, shortName: String, args: List[Type]): Type {
        val dotIndex = shortName.indexOf(".")
        val outerShortName = if dotIndex == -1 { shortName } else { shortName[:dotIndex] }
        if val data = scope.getOrNull(outerShortName) {
            when data {
                case fullName(prefix) {
                    val fullName = if dotIndex == -1 { prefix } else {
                        prefix + "." + shortName[dotIndex + 1:]
                    }
                    Type.reified(getReifiedType(mark, fullName, args))
                }
                case type(type) {
                    if args {
                        throw CJError("Unexpected type args", [mark])
                    }
                    type
                }
            }
        } else { throw CJError("Name " + outerShortName + " not found in this scope", [mark]) }
    }

    def getReifiedType(self, mark: CJMark, fullName: String, args: List[Type]): ReifiedType {
        if val itemdef = getItemDefOrNull(fullName) {
            if itemdef.typeParameters and not args.size() and not fullName.endsWith("_") {
                return getReifiedType(mark, fullName + "_", args)
            }
            if itemdef.typeParameters.size() != args.size() {
                throw CJError(
                    "Expected " + itemdef.typeParameters.size() +
                    " args but got " + args.size(), [mark])
            }
            val classOrUnionDef = when itemdef {
                case class_(cls) = CJIR.ClassOrUnionDef.class_(cls)
                case union_(uni) = CJIR.ClassOrUnionDef.union_(uni)
                case trait_(..) = return if not fullName.endsWith("_") {
                    getReifiedType(mark, fullName + "_", args)
                } else { throw CJError(fullName + " is a trait, not a type", [mark]) }
            }
            val rtype = ReifiedType(classOrUnionDef, args)
            _checkTypeArgs(mark, rtype._getBinding(), classOrUnionDef.typeParameters, args)
            rtype
        } else { throw CJError("Item " + fullName + " not found", [mark]) }
    }

    def getReifiedTrait(self, mark: CJMark, fullName: String, args: List[Type]): Trait {
        if val itemdef = getItemDefOrNull(fullName) {
            if itemdef.typeParameters.size() != args.size() {
                throw CJError(
                    "Expected " + itemdef.typeParameters.size() +
                    " args but got " + args.size(), [mark])
            }
            val traitdef = when itemdef {
                case trait_(t) = t
                else = throw CJError(fullName + " is a type, not a trait", [mark])
            }
            val trait_ = Trait(traitdef, args)
            _checkTypeArgs(mark, trait_._getBinding(), traitdef.typeParameters, args)
            trait_
        } else { throw CJError("Item " + fullName + " not found", [mark]) }
    }

    def _checkTypeArgs(
            self,
            mark: CJMark,
            binding: CJIR.Binding,
            params: List[CJIR.TypeParameter],
            args: List[Type]) {
        if params.size() != args.size() {
            throw CJError(
                "Expected " + params.size() + " type args but got " + args.size(), [mark])
        }
        for i = 0; i < args.size(); i++ {
            val param = params[i]
            val arg = args[i]
            for originalTrait in param.traits {
                val trait_ = originalTrait.applyBinding(mark, binding)
                if not arg.implementsTrait(mark, trait_) {
                    throw CJError("" + arg + " does not implement " + trait_, [mark, param.mark])
                }
            }
        }
    }

    def solveTypeCondition(self, scope: CJScope, astCond: CJAst.TypeCondition): CJIR.TypeCondition {
        val traits = astCond.traits.map(t -> solveTrait(scope, t))
        CJIR.TypeCondition(astCond.mark, astCond.variableName, traits)
    }
}
